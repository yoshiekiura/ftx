class Withdraw < ActiveRecord::Base
  #require 'newrelic_rpm'
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  STATES = [:submitting, :submitted, :rejected, :accepted, :suspect, :processing,
            :done, :cancelled, :almost_done, :failed, :warning, :checked]
  COMPLETED_STATES = [:done, :rejected, :canceled, :almost_done, :failed]

  extend Enumerize

  include AASM
  include AASM::Locking
  include Currencible

  has_paper_trail on: [:update, :destroy]

  enumerize :aasm_state, in: STATES, scope: true

  belongs_to :member
  belongs_to :account
  has_many :account_versions, as: :modifiable

  delegate :balance, to: :account, prefix: true
  delegate :key_text, to: :channel, prefix: true
  delegate :id, to: :channel, prefix: true
  delegate :name, to: :member, prefix: true
  delegate :coin?, :fiat?, to: :currency_obj

  before_validation :fix_precision
  before_validation :calc_fee
  before_validation :set_account
  after_create :generate_sn

  after_update :sync_update
  after_create :sync_create
  after_destroy :sync_destroy

  validates_with WithdrawBlacklistValidator

  validates :fund_uid, :amount, :fee, :account, :currency, :member, presence: true

  validates :fee, numericality: {greater_than_or_equal_to: 0}
  validates :amount, numericality: {greater_than: 0}

  validates :sum, presence: true, numericality: {greater_than: 0}, on: :create
  validates :txid, uniqueness: true, allow_nil: true, on: :update

  validate :ensure_account_balance, on: :create

  scope :completed, -> { where aasm_state: COMPLETED_STATES }
  scope :not_completed, -> { where.not aasm_state: COMPLETED_STATES }

  def self.channel
    WithdrawChannel.find_by_key(name.demodulize.underscore)
  end

  def channel
    self.class.channel
  end

  def channel_name
    channel.key
  end

  alias_attribute :withdraw_id, :sn
  alias_attribute :full_name, :member_name

  def generate_sn
    id_part = sprintf '%04d', id
    date_part = created_at.localtime.strftime('%y%m%d%H%M')
    self.sn = "#{date_part}#{id_part}"
    update_column(:sn, sn)
  end

  aasm :whiny_transitions => false do
    state :submitting,  initial: true
    state :submitted,   after_commit: :send_email
    state :canceled,    after_commit: :send_email
    state :accepted,    after_commit: :send_email
    state :suspect,     after_commit: :send_email
    state :rejected,    after_commit: :send_email
    state :processing,  after_commit: :send_email
    state :almost_done,  after_commit: :send_email
    state :done,        after_commit: :send_email
    state :failed,      after_commit: :send_email

    event :submit do
      transitions from: :submitting, to: :submitted
      after do
        lock_funds
      end
    end

    event :cancel do
      transitions from: [:submitting, :submitted, :accepted], to: :canceled
      after do
        after_cancel
      end
    end

    event :mark_suspect do
      transitions from: :submitted, to: :suspect
    end

    event :accept do
      transitions from: :submitted, to: :accepted
    end

    event :reject do
      transitions from: [:submitted, :accepted, :processing, :almost_done], to: :rejected
      after :unlock_funds
    end

    event :process do
      transitions from: :accepted, to: :processing
    end

    event :call_rpc do
      transitions from: :processing, to: :almost_done
    end

    event :succeed do
      transitions from: [:processing, :almost_done], to: :done

      before [:set_txid, :unlock_and_sub_funds]
    end

    event :fail do
      transitions from: [:processing, :almost_done], to: :failed
    end
  end

  def cancelable?
    submitting? or submitted? or accepted? 
  end

  def quick?
    sum <= currency_obj.quick_withdraw_max
  end

  def audit!
    with_lock do
      #if account.examine
      accept
      send_coins! if quick?
      process if quick?
      #else
      #  mark_suspect
      #end

      save!
    end
  end

  private

  def after_cancel
    unlock_funds unless aasm.from_state == :submitting
  end

  def lock_funds
    account.lock!
    account.lock_funds sum, reason: Account::WITHDRAW_LOCK, ref: self
  end

  def unlock_funds
    account.lock!
    account.unlock_funds sum, reason: Account::WITHDRAW_UNLOCK, ref: self
  end

  def unlock_and_sub_funds
    account.lock!
    account.unlock_and_sub_funds sum, locked: sum, fee: fee, reason: Account::WITHDRAW, ref: self

    if self.class == Withdraws::Bank
      member_fee = Member.find_by_email(Figaro.env.financial.split(',')[0])
      acc_fee = Account.where(member_id: member_fee.id, currency: 1).first()
      acc_fee.plus_funds(self.fee, reason: Account::STRIKE_FEE_WITHDRAW, ref: self)
    end

  end

  def set_txid
    self.txid = @sn unless coin?
  end

  def send_email
    begin
      case aasm_state
      when 'submitted'
        WithdrawMailer.submitted(self.id)
        SystemMailer.withdraw_status_change(self)
      when 'processing'
        WithdrawMailer.processing(self.id)
      when 'done'
        WithdrawMailer.done(self.id)
      else
        WithdrawMailer.withdraw_state(self.id)
      end
    rescue
      puts "Fail send email"
    end
  end

  def send_sms
    return true if not member.sms_two_factor.activated?

    sms_message = I18n.t('sms.withdraw_done', email: member.email,
                                              currency: currency_text,
                                              time: I18n.l(Time.now),
                                              amount: amount,
                                              balance: account.balance)

    AMQPQueue.enqueue(:sms_notification, phone: member.phone_number, message: sms_message)
  end

  def send_coins!
    AMQPQueue.enqueue(:withdraw_coin, id: id) if coin?
  end

  def ensure_account_balance
    if sum.nil? or sum > account.balance
      errors.add :base, -> { I18n.t('activerecord.errors.models.withdraw.account_balance_is_poor') }
    end
  end

  def fix_precision
    if sum && currency_obj.precision
      self.sum = sum.round(currency_obj.precision, BigDecimal::ROUND_DOWN)
    end
  end

  def calc_fee
    if respond_to?(:set_fee)
      set_fee
    end

    self.sum ||= 0.0
    self.fee ||= 0.0
    self.amount = sum - fee
  end

  def set_account
    self.account = member.get_account(currency)
  end

  def self.resource_name
    name.demodulize.underscore.pluralize
  end

  def sync_update
    ::Pusher["private-#{member.sn}"].trigger_async('withdraws', { type: 'update', id: self.id, attributes: self.changes_attributes_as_json })
    Rails.cache.write "peatio:withdraw:#{self.fund_uid}:#{self.currency}:data", self
  end

  def sync_create
    ::Pusher["private-#{member.sn}"].trigger_async('withdraws', { type: 'create', attributes: self.as_json })
  end

  def sync_destroy
    ::Pusher["private-#{member.sn}"].trigger_async('withdraws', { type: 'destroy', id: self.id })
  end

  def enqueue_state

    payload = self.as_json
    Rails.cache.write "peatio:withdraw:#{self.fund_uid}:#{self.currency}:data", self
    Rails.cache.write "peatio:withdraw:#{self.fund_uid}:#{self.currency}:state", 1
    AMQPQueue.enqueue(:withdraw_txid, payload, {persistent: true})

  end

  # add_transaction_tracer :channel,
  #                        :name => 'channel',
  #                        :category => "Withdraw/channel"
  # add_transaction_tracer :channel_name,
  #                        :name => 'channel_name',
  #                        :category => "Withdraw/channel_name"
  # add_transaction_tracer :generate_sn,
  #                        :name => 'generate_sn',
  #                        :category => "Withdraw/generate_sn"
  # add_transaction_tracer :cancelable?,
  #                        :name => 'cancelable?',
  #                        :category => "Withdraw/cancelable?"
  # add_transaction_tracer :quick?,
  #                        :name => 'quick?',
  #                        :category => "Withdraw/quick?"
  # add_transaction_tracer :audit!,
  #                        :name => 'audit!',
  #                        :category => "Withdraw/audit!"
  # add_transaction_tracer :after_cancel,
  #                        :name => 'after_cancel',
  #                        :category => "Withdraw/after_cancel"
  # add_transaction_tracer :lock_funds,
  #                        :name => 'lock_funds',
  #                        :category => "Withdraw/lock_funds"
  # add_transaction_tracer :send_email,
  #                        :name => 'send_email',
  #                        :category => "Withdraw/send_email"
  # add_transaction_tracer :send_sms,
  #                        :name => 'send_sms',
  #                        :category => "Withdraw/send_sms"
  # add_transaction_tracer :send_coins!,
  #                        :name => 'send_coins!',
  #                        :category => "Withdraw/send_coins!"
  # add_transaction_tracer :ensure_account_balance,
  #                        :name => 'ensure_account_balance',
  #                        :category => "Withdraw/ensure_account_balance"
  # add_transaction_tracer :calc_fee,
  #                        :name => 'calc_fee',
  #                        :category => "Withdraw/calc_fee"
  # add_transaction_tracer :set_account,
  #                        :name => 'set_account',
  #                        :category => "Withdraw/set_account"
  # add_transaction_tracer :sync_update,
  #                        :name => 'sync_update',
  #                        :category => "Withdraw/sync_update"
  # add_transaction_tracer :sync_create,
  #                        :name => 'sync_create',
  #                        :category => "Withdraw/sync_create"
  # add_transaction_tracer :sync_destroy,
  #                        :name => 'sync_destroy',
  #                        :category => "Withdraw/sync_destroy"
end
