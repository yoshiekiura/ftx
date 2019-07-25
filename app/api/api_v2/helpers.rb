module APIv2
  module Helpers

    def authenticate!
      current_user or raise AuthorizationError
    end

    def redis
      @r ||= KlineDB.redis
    end

    def current_user
      @current_user ||= current_token.try(:member)
    end

    def current_token
      @current_token ||= env['api_v2.token']
    end

    def current_market
      @current_market ||= Market.find params[:market]
    end

    def time_to
      params[:timestamp].present? ? Time.at(params[:timestamp]) : nil
    end

    def build_order(attrs)
      klass = attrs[:side] == 'sell' ? OrderAsk : OrderBid

      order = klass.new(
        source:        'APIv2',
        state:         ::Order::WAIT,
        member_id:     current_user.id,
        ask:           current_market.base_unit,
        bid:           current_market.quote_unit,
        currency:      current_market.id,
        ord_type:      attrs[:ord_type] || 'limit',
        price:         attrs[:price],
        volume:        attrs[:volume],
        origin_volume: attrs[:volume]
      )
    end

    def create_order(attrs)
      order = build_order attrs
      Ordering.new(order).submit
      order
    rescue
      Rails.logger.info "Failed to create order: #{$!}"
      Rails.logger.debug order.inspect
      Rails.logger.debug $!.backtrace.join("\n")
      raise CreateOrderError, $!
    end

    def create_orders(multi_attrs)
      orders = multi_attrs.map {|attrs| build_order attrs }
      Ordering.new(orders).submit
      orders
    rescue
      Rails.logger.info "Failed to create order: #{$!}"
      Rails.logger.debug $!.backtrace.join("\n")
      raise CreateOrderError, $!
    end

    def order_param
      params[:order_by].downcase == 'asc' ? 'id asc' : 'id desc'
    end

    def format_ticker(ticker)
      { at: ticker[:at],
        ticker: {
          buy: ticker[:buy],
          sell: ticker[:sell],
          low: ticker[:low],
          high: ticker[:high],
          last: ticker[:last],
          vol: ticker[:volume]
        }
      }
    end

    def key_for_time(period)
      raise "abstract method"
    end

    def get_k_json
      key = "peatio:#{params[:market]}:k:#{params[:period]}"

      if params[:timestamp]
        ts = JSON.parse(redis.lindex(key, 0)).first
        offset = (params[:timestamp] - ts) / 60 / params[:period]
        offset = 0 if offset < 0

        JSON.parse('[%s]' % redis.lrange(key, offset, offset + params[:limit] - 1).join(','))
      else
        length = redis.llen(key)
        offset = [length - params[:limit], 0].max
        JSON.parse('[%s]' % redis.lrange(key, offset, -1).join(','))
      end
    end


    def get_points_twe(symbol, resolution, from, to)

      # Relation of ranges and seconds "sum"
      times = { '1': 1,
                '5': 5,
                '15': 15,
                '30': 30,
                '60': 60,
                '120': 120,
                '240': 240,
                '360': 360,
                '720': 720,
                'd': 1440,
                '1d': 1440,
                '1w': 10080,
                '1m': 43800,
                '6m': 262800
      }
      time_line = times[resolution.downcase.to_sym]

      if symbol and time_line

        key_line = "peatio:#{symbol}:k:#{time_line}"
        ts_first = redis.lindex(key_line, 0)

        return {trades: []} if ts_first.nil? or ts_first.to_s.empty?

        ts_first_value = MultiJson.decode(ts_first.to_s)[0].to_i

        # Check if there are data
        if to >= ts_first_value

          ts_latest = redis.lindex(key_line, -1)
          length = redis.llen(key_line)

          from_sub = ts_first.to_i - from.to_i
          from_div  = from_sub / time_line.to_i

          to_sub = ts_latest.to_i - to.to_i
          to_div =  to_sub / time_line.to_i

          ret_jump = from_div - to_div
          position_jump = ret_jump.to_i / time_line.to_i
          points_to = [length - position_jump, 0].max

          trades = redis.lrange(key_line, points_to , points_to + position_jump)

          {trades: trades}
        else
          {trades: []}
        end
      else
        {trades: []}
      end
    rescue
      Rails.logger.error "Error on get_points_twe: #{$!}"
      Rails.logger.error "symbol #{symbol.inspect} resolution #{resolution.inspect} from #{from.inspect} to #{to.inspect}"
      Rails.logger.error $!.backtrace.join("\n")

      {trades: []}
    end

  end
end
