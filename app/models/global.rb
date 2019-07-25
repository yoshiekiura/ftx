class Global
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  ZERO = '0.0'.to_d
  NOTHING_ARRAY = YAML::dump([])
  LIMIT = 80

  class << self
    #include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    def channel
      "market-global"
    end

    def trigger(event, data)
      Pusher.trigger_async(channel, event, data)
    end

    def daemon_statuses
      Rails.cache.fetch('peatio:daemons:statuses', expires_in: 3.minute) do
        Daemons::Rails::Monitoring.statuses
      end
    end
    # add_transaction_tracer :channel,
    #                        :name => 'channel',
    #                        :category => "Global/channel"
    # add_transaction_tracer :daemon_statuses,
    #                        :name => 'daemon_statuses',
    #                        :category => "Global/daemon_statuses"
    # add_transaction_tracer :trigger,
    #                        :name => 'trigger',
    #                        :category => "Global/trigger"
  end

  def initialize(currency)

    @currency = currency
  end

  def channel
    "market-#{@currency}-global"
  end

  def channel_all
    "market-global-all"
  end

  attr_accessor :currency

  def self.[](market)
    if market.is_a? Market
      self.new(market.id)
    else
      self.new(market)
    end
  end

  def key(key, interval=5)
    seconds  = Time.now.to_i
    time_key = seconds - (seconds % interval)
    "peatio:#{@currency}:#{key}:#{time_key}"
  end

  def asks
    Rails.cache.read("peatio:#{currency}:depth:asks") || []
  end

  def bids
    Rails.cache.read("peatio:#{currency}:depth:bids") || []
  end

  def default_ticker
    {low: ZERO, high: ZERO, last: ZERO, volume: ZERO}
  end

  def ticker
    ticker           = Rails.cache.read("peatio:#{currency}:ticker") || default_ticker
    open = Rails.cache.read("peatio:#{currency}:ticker:open") || ticker[:last]
    open = open.to_d
    best_buy_price   = bids.first && bids.first[0] || ZERO
    best_sell_price  = asks.first && asks.first[0] || ZERO

    current_price = Trade.with_currency(currency).latest.try(:price) || ZERO
    percentage_volume  = (Trade.with_currency(currency).h24.sum(:volume) / 9 * 100).round || ZERO
  
    last_24_price = Trade.with_currency(currency).h24.try(:price) || ZERO
    
    last_24_divisor = (last_24_price == ZERO) ? 1 : last_24_price 
    existent_divisor = (open == ZERO) ? 1 : open

    # last_existent_quotient = (current_price - open) * -1 if (current_price - open) < 0 || ZERO
    # last_existent_quotient = (current_price - open) * 1 if (current_price - open) >= 0 || ZERO

    last_existent_quotient = 0
    #
    # last_24_price_quotient = (current_price - last_24_price) * -1 if (current_price - last_24_price) < 0
    # last_24_price_quotient = (current_price - last_24_price) * 1 if (current_price - last_24_price) >= 0

    last_24_price_quotient = 0

    # last_24_percentage = ((last_24_price_quotient / last_24_divisor) * 100)  if last_24_price > 0
    # last_24_percentage = ((last_existent_quotient / existent_divisor) * 100) if last_24_price == 0 || ZERO

    last_24_percentage = 0

    ticker.merge({
      open: open,
      volume: h24_volume,
      sell: best_sell_price,
      buy: best_buy_price,
      at: at,
      percentage_volume: percentage_volume,
      last_24_percentage: (last_24_percentage).round(2)
    })
  end


  def h24_volume
    Rails.cache.fetch key('h24_volume', 5), expires_in: 24.hours do
      Trade.with_currency(currency).h24.sum(:volume) || ZERO
    end
  end

  def trades
    Rails.cache.read("peatio:#{currency}:trades") || []
  end

  def trigger_orderbook
    data = {asks: asks, bids: bids}
    Pusher.trigger_async(channel, "update", data)
  end

  def trigger_trades(trades)
    Pusher.trigger_async(channel, "trades", trades: trades)
  end

  def at
    @at ||= DateTime.now.to_i
  end

  # add_transaction_tracer :initialize,
  #                        :name => 'initialize',
  #                        :category => "Global/initialize"
  # add_transaction_tracer :channel,
  #                        :name => 'channel',
  #                        :category => "Global/channel"
  # add_transaction_tracer :channel_all,
  #                        :name => 'channel_all',
  #                        :category => "Global/channel_all"
  # add_transaction_tracer :key,
  #                        :name => 'key',
  #                        :category => "Global/key"
  # add_transaction_tracer :asks,
  #                        :name => 'asks',
  #                        :category => "Global/asks"
  # add_transaction_tracer :bids,
  #                        :name => 'bids',
  #                        :category => "Global/bids"
  # add_transaction_tracer :default_ticker,
  #                        :name => 'default_ticker',
  #                        :category => "Global/default_ticker"
  # add_transaction_tracer :ticker,
  #                        :name => 'ticker',
  #                        :category => "Global/ticker"
  # add_transaction_tracer :h24_volume,
  #                        :name => 'h24_volume',
  #                        :category => "Global/h24_volume"
  # add_transaction_tracer :trades,
  #                        :name => 'trades',
  #                        :category => "Global/trades"
  # add_transaction_tracer :trigger_orderbook,
  #                        :name => 'trigger_orderbook',
  #                        :category => "Global/trigger_orderbook"
  # add_transaction_tracer :trigger_trades,
  #                        :name => 'trigger_trades',
  #                        :category => "Global/trigger_trades"


end
