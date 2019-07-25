class OrderAsk < Order
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  has_many :trades, foreign_key: 'ask_id'

  scope :matching_rule, -> { order('price ASC, created_at ASC') }

  after_create :sync_create
  
  attr_accessor :last_ask
  attr_accessor :volume_holder

  def volume_holder
    @volume_holder = 0.0
  end

  def get_account_changes(trade)
    [trade.volume, trade.funds]
  end

  def hold_account
    member.get_account(ask)
  end

  def expect_account
    member.get_account(bid)
  end

  def avg_price
    return ::Trade::ZERO if funds_used.zero?
    config.fix_number_precision(:bid, funds_received / funds_used)
  end

  def sync_create
    ::Pusher["market-#{Global[currency].currency}-orders"].trigger_async('new', { type: "ask", ord_type: "#{self[:ord_type]}", order: { currency: self[:currency], price: Global[currency].ticker[:sell], volume: Global[currency].ticker[:volume]} })
  end

  def compute_locked
    case ord_type
    when 'limit'
      volume
    when 'market'
      estimate_required_funds(Global[currency].bids) {|p, v| v}
    end
  end
  # add_transaction_tracer :volume_holder,
  #                        :name => 'volume_holder',
  #                        :category => "OrderAsk/volume_holder"
  # add_transaction_tracer :get_account_changes,
  #                        :name => 'get_account_changes',
  #                        :category => "OrderAsk/get_account_changes"
  # add_transaction_tracer :hold_account,
  #                        :name => 'hold_account',
  #                        :category => "OrderAsk/hold_account"
  # add_transaction_tracer :expect_account,
  #                        :name => 'expect_account',
  #                        :category => "OrderAsk/expect_account"
  # add_transaction_tracer :avg_price,
  #                        :name => 'avg_price',
  #                        :category => "OrderAsk/avg_price"
  # add_transaction_tracer :sync_create,
  #                        :name => 'sync_create',
  #                        :category => "OrderAsk/sync_create"
  # add_transaction_tracer :compute_locked,
  #                        :name => 'compute_locked',
  #                        :category => "OrderAsk/compute_locked"
end
