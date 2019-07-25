module Worker
  require 'newrelic_rpm'
  class MarketTicker
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    FRESH_TRADES = 80

    def initialize
      @tickers = {}
      @trades  = {}

      Market.all.each do |market|
        initialize_market_data market
      end
    end

    def process(payload, metadata, delivery_info)
      trade = Trade.new payload
      update_ticker trade
      update_latest_trades trade
    end

    def update_ticker(trade)

      trade = trade.for_global

      puts trade[:market].inspect

      ticker        = @tickers[trade[:market]]
      ticker[:low]  = get_market_low trade[:market], trade
      ticker[:high] = get_market_high trade[:market], trade
      ticker[:last] = trade[:price]
      Rails.logger.info ticker.inspect
      Rails.cache.write "peatio:#{trade[:market]}:ticker", ticker
    end

    def update_latest_trades(trade)

      trade = trade.for_global
      trades = @trades[trade[:market]]
      trades.unshift(trade)
      trades.pop if trades.size > FRESH_TRADES

      Rails.cache.write "peatio:#{trade[:market]}:trades", trades
    end

    def initialize_market_data(market)
      trades_market = Trade.none
      trades = Trade.with_currency(market)
      trades.each do | trade |
        if trade.bid.bid == market.quote_unit
          trades_market << trade
        end
      end

      @trades[market.id] = trades_market.order('id desc').limit(FRESH_TRADES).map(&:for_global)
      Rails.cache.write "peatio:#{market.id}:trades", @trades[market.id]

      low_trade = initialize_market_low(market.id)
      high_trade = initialize_market_high(market.id)

      @tickers[market.id] = {
        low:  low_trade.try(:price)   || ::Trade::ZERO,
        high: high_trade.try(:price)  || ::Trade::ZERO,
        last: trades.last.try(:price) || ::Trade::ZERO
      }
      Rails.cache.write "peatio:#{market.id}:ticker", @tickers[market.id]
    end

    private

    def get_market_low(market, trade)

      low_key = "peatio:#{market}:h24:low"
      low = Rails.cache.read(low_key)

      if low.nil?
        trade = initialize_market_low(market)
        low = trade[:price].to_d
      elsif trade[:price].to_d < low
        low = trade[:price].to_d
        write_h24_key low_key, low
      end

      low
    end

    def get_market_high(market, trade)

      high_key = "peatio:#{market}:h24:high"
      high = Rails.cache.read(high_key)

      if high.nil?
        trade = initialize_market_high(market)
        high = trade[:price].to_d
      elsif trade[:price].to_d > high
        high = trade[:price].to_d
        write_h24_key high_key, high
      end

      high
    end

    def initialize_market_low(market)

      if low_trade = Trade.with_currency(market).h24.order('price asc').first
        ttl = low_trade.created_at.to_i + 24.hours - Time.now.to_i
        write_h24_key "peatio:#{market}:h24:low", low_trade.price, ttl
        low_trade
      end
    end

    def initialize_market_high(market)

      if high_trade = Trade.with_currency(market).h24.order('price desc').first
        ttl = high_trade.created_at.to_i + 24.hours - Time.now.to_i
        write_h24_key "peatio:#{market}:h24:high", high_trade.price, ttl
        high_trade
      end
    end

    def write_h24_key(key, value, ttl=24.hours)
      Rails.cache.write key, value, expires_in: ttl
    end
      add_transaction_tracer :process, :category => :task
      add_transaction_tracer :update_ticker, :category => :task
      add_transaction_tracer :update_latest_trades, :category => :task
      add_transaction_tracer :initialize_market_data, :category => :task
      add_transaction_tracer :get_market_low, :category => :task
      add_transaction_tracer :get_market_high, :category => :task
      add_transaction_tracer :initialize_market_low, :category => :task
      add_transaction_tracer :initialize_market_high, :category => :task
  end
end
