class OrderBid < Order
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  has_many :trades, foreign_key: 'bid_id'

  scope :matching_rule, -> { order('price DESC, created_at ASC') }

  attr_accessor :last_bid
  attr_accessor :volume_holder
  before_create :sync_create

  def volume_holder
    @volume_holder = 0.0
  end
  
  def get_account_changes(trade)
    [trade.funds, trade.volume]
  end

  def hold_account
    member.get_account(bid)
  end

  def expect_account
    member.get_account(ask)
  end

  def avg_price
    return ::Trade::ZERO if funds_received.zero?
    config.fix_number_precision(:bid, funds_used / funds_received)
  end

  def sync_create
    ::Pusher["market-#{Global[currency].currency}-orders"].trigger_async('new', { type: "bid", ord_type: "#{self[:ord_type]}", order: { currency: self[:currency], price: Global[currency].ticker[:buy], volume: Global[currency].ticker[:volume]} })
  end

  LOCKING_BUFFER_FACTOR = '1.1'.to_d
  def compute_locked
    case ord_type
    when 'limit'
      price*volume
    when 'market'
      funds = estimate_required_funds(Global[currency].asks) {|p, v| p*v }
      funds*LOCKING_BUFFER_FACTOR
    end
  end
  # add_transaction_tracer :volume_holder,
  #                        :name => 'volume_holder',
  #                        :category => "OrderBid/volume_holder"
  # add_transaction_tracer :get_account_changes,
  #                        :name => 'get_account_changes',
  #                        :category => "OrderBid/get_account_changes"
  # add_transaction_tracer :hold_account,
  #                        :name => 'hold_account',
  #                        :category => "OrderBid/hold_account"
  # add_transaction_tracer :expect_account,
  #                        :name => 'expect_account',
  #                        :category => "OrderBid/expect_account"
  # add_transaction_tracer :sync_create,
  #                        :name => 'sync_create',
  #                        :category => "OrderBid/sync_create"
  # add_transaction_tracer :compute_locked,
  #                        :name => 'compute_locked',
  #                        :category => "OrderBid/compute_locked"

end
