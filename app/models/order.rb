class Order < ActiveRecord::Base
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  extend Enumerize

  enumerize :bid, in: Currency.enumerize
  enumerize :ask, in: Currency.enumerize
  enumerize :currency, in: Market.enumerize, scope: true
  enumerize :state, in: {:wait => 100, :done => 200, :cancel => 0}, scope: true

  ORD_TYPES = %w(market limit)
  enumerize :ord_type, in: ORD_TYPES, scope: true

  SOURCES = %w(Web APIv2 debug)
  enumerize :source, in: SOURCES, scope: true

  after_commit :trigger
  before_validation :fix_number_precision, on: :create

  validates_presence_of :ord_type, :volume, :origin_volume, :locked, :origin_locked
  validates_numericality_of :origin_volume, :greater_than => 0

  validates_numericality_of :price, greater_than: 0, allow_nil: false,
    if: "ord_type == 'limit'"
  validate :market_order_validations, if: "ord_type == 'market'"

  WAIT = 'wait'
  DONE = 'done'
  CANCEL = 'cancel'

  ATTRIBUTES = %w(id at market bid ask kind price state state_text volume origin_volume)

  belongs_to :member
  attr_accessor :total

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  scope :position, -> { group("price").pluck(:price, 'sum(volume)') }
  scope :best_price, ->(currency) { where(ord_type: 'limit').active.with_currency(currency).matching_rule.position }

  def funds_used
    origin_locked - locked
  end

  def fee
    config[kind.to_sym]["fee"]
  end

  def config
    @config ||= Market.find(currency)
  end

  def trigger
    return unless member

    json = Jbuilder.encode do |json|
      json.(self, *ATTRIBUTES)
    end
    member.trigger('order', json)
  end

  def strike(trade)
    raise "Cannot strike on cancelled or done order. id: #{id}, state: #{state}" unless state == Order::WAIT
    real_sub, add = get_account_changes trade
    real_fee      = (add * fee) / 100
    real_add      = add - real_fee

    hold_account.unlock_and_sub_funds \
      real_sub, locked: real_sub,
      reason: Account::STRIKE_SUB, ref: trade

    expect_account.plus_funds \
      real_add, fee: real_fee,
      reason: Account::STRIKE_ADD, ref: trade

    if self.type == 'OrderBid'
      member_fee = Member.find_by_email(Figaro.env.financial.split(',')[0])
      acc_fee = Account.where(member_id: member_fee.id, currency: self[:ask]).first()
      acc_fee.plus_funds(real_fee, reason: Account::STRIKE_FEE, ref: trade)
    end


    if self.type == 'OrderAsk'
      member_fee = Member.find_by_email(Figaro.env.financial.split(',')[0])
      acc_fee = Account.where(member_id: member_fee.id, currency: self[:bid]).first()
      acc_fee.plus_funds(real_fee, reason: Account::STRIKE_FEE, ref: trade)
    end


    self.volume         -= trade.volume
    self.locked         -= real_sub
    self.funds_received += add
    self.trades_count   += 1

    if volume.zero?
      self.state = Order::DONE

      # unlock not used funds
      hold_account.unlock_funds locked,
        reason: Account::ORDER_FULLFILLED, ref: trade unless locked.zero?
    elsif ord_type == 'market' && locked.zero?
      # partially filled market order has run out its locked fund
      self.state = Order::CANCEL
    end

    self.save!
  end

  def kind
    type.underscore[-3, 3]
  end

  def self.head(currency)
    active.with_currency(currency.downcase).matching_rule.first
  end

  def at
    created_at.to_i
  end

  def market
    ask+bid
  end

  def to_matching_attributes
    { id: id,
      market: ask+bid,
      type: type[-3, 3].downcase.to_sym,
      ord_type: ord_type,
      volume: volume,
      price: price,
      locked: locked,
      timestamp: created_at.to_i }
  end

  def fix_number_precision
    self.price = config.fix_number_precision(:bid, price.to_d) if price

    if volume
      self.volume = config.fix_number_precision(:ask, volume.to_d)
      self.origin_volume = origin_volume.present? ? config.fix_number_precision(:ask, origin_volume.to_d) : volume
    end
  end

  private

  def market_order_validations
    errors.add(:price, 'must not be present') if price.present?
  end

  FUSE = '0.9'.to_d
  def estimate_required_funds(price_levels)
    required_funds = Account::ZERO
    expected_volume = volume

    start_from, _ = price_levels.first
    filled_at     = start_from

    until expected_volume.zero? || price_levels.empty?
      level_price, level_volume = price_levels.shift
      filled_at = level_price
      level_volume = level_volume[1] if level_volume.kind_of?(Array)
      expected_volume = expected_volume[1] if expected_volume.kind_of?(Array)
      v = [expected_volume, level_volume].min
      required_funds += yield level_price, v
      expected_volume -= v
    end

    raise "Market is not deep enough" unless expected_volume.zero?
    raise "Volume too large" if (filled_at-start_from).abs/start_from > FUSE

    required_funds
  end
  # add_transaction_tracer :funds_used,
  #                        :name => 'funds_used',
  #                        :category => "Order/funds_used"
  # add_transaction_tracer :fee,
  #                        :name => 'fee',
  #                        :category => "Order/fee"
  # add_transaction_tracer :config,
  #                        :name => 'config',
  #                        :category => "Order/config"
  # add_transaction_tracer :trigger,
  #                        :name => 'trigger',
  #                        :category => "Order/trigger"
  # add_transaction_tracer :strike,
  #                        :name => 'strike',
  #                        :category => "Order/strike"
  # add_transaction_tracer :to_matching_attributes,
  #                        :name => 'to_matching_attributes',
  #                        :category => "Order/to_matching_attributes"
  # add_transaction_tracer :fix_number_precision,
  #                        :name => 'fix_number_precision',
  #                        :category => "Order/fix_number_precision"
  # add_transaction_tracer :market_order_validations,
  #                        :name => 'market_order_validations',
  #                        :category => "Order/market_order_validations"
  # add_transaction_tracer :estimate_required_funds,
  #                        :name => 'estimate_required_funds',
  #                        :category => "Order/estimate_required_funds"



end
