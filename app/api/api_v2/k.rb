module APIv2
  class K < Grape::API
    helpers ::APIv2::NamedParams

    desc 'Get OHLC(k line) of specific market.'
    params do
      use :market
      optional :limit,     type: Integer, default: 30, values: 1..10000, desc: "Limit the number of returned data points, default to 30."
      optional :period,    type: Integer, default: 1, values: [1, 5, 15, 30, 60, 120, 240, 360, 720, 1440, 4320, 43800 ,10080, 262800, 525600], desc: "Time period of K line, default to 1. You can choose between 1, 5, 15, 30, 60, 120, 240, 360, 720, 1440, 4320, 10080"
      optional :timestamp, type: Integer, desc: "An integer represents the seconds elapsed since Unix epoch. If set, only k-line data after that time will be returned."
    end
    get "/k" do
      get_k_json
    end

    desc "Get K data with pending trades, which are the trades not included in K data yet, because there's delay between trade generated and processed by K data generator."
    params do
      use :market
      requires :trade_id,  type: Integer, desc: "The trade id of the first trade you received."
      optional :limit,     type: Integer, default: 30, values: 1..10000, desc: "Limit the number of returned data points, default to 30."
      optional :period,    type: Integer, default: 1, values: [1, 5, 15, 30, 60, 120, 240, 360, 720, 1440, 4320, 43800 ,10080, 262800, 525600], desc: "Time period of K line, default to 1. You can choose between 1, 5, 15, 30, 60, 120, 240, 360, 720, 1440, 4320, 10080"
      optional :timestamp, type: Integer, desc: "An integer represents the seconds elapsed since Unix epoch. If set, only k-line data after that time will be returned."
    end
    get "/k_with_pending_trades" do
      k = get_k_json

      if params[:trade_id] > 0
        from = Time.at k.last[0]
        trades = Trade.with_currency(params[:market])
          .where('created_at >= ? AND id < ?', from, params[:trade_id])
          .map(&:for_global)

        {k: k, trades: trades}
      else
        {k: k, trades: []}
      end
    end

    ######################################
    # TradingView UDF implementation
    # https://github.com/tradingview/charting_library/wiki/UDF
    ######################################

    desc 'Get feed server time'
    get "/time" do
      Time.now.to_i
    end

    desc 'Get data feed configuration data'
    get "/config" do
      { supported_resolutions: ['1','5','15','30','60','120','240','360','720','1D','1W','1M','6M'],
        supports_group_request: false,
        supports_marks: false,
        supports_search: true,
        supports_timescale_marks: false }
    end

    # /symbols?symbol=<symbol>
    desc 'Get symbols'
    params do
      requires :symbol,  type: String, desc: "no desc"
    end
    get "/symbols" do
      market = Market.find_by_id(params[:symbol])
      market = Market.find_by_name(params[:symbol]) if market.nil?
      market = Market.find_by_base_unit(params[:symbol]) if market.nil?

      unless market.nil?
        {"name": market.name ,
         "exchange-traded":params[:symbol],
         "exchange-listed":params[:symbol],
         "timezone":ENV['TIMEZONE'],
         "minmov":1,
         "minmov2":0,
         "pointvalue":1,
         "pricescale":100,
         "session":"24x7",
         "has_intraday":true,
         "has_no_volume":false,
         "description": market.name,
         "type": market.base_unit,
         "supported_resolutions":['1','5','15','30','60','120','240','360','720','1D','1W','1M','6M'],
         "ticker": params[:symbol] }
      else
        {}
      end
    end

    # /history?symbol=BEAM~0&resolution=D&from=1386493512&to=1395133512
    desc 'Get quotes'
    params do
      requires :symbol,  type: String, desc: "no desc"
      requires :from, type: Integer, desc: "no desc"
      requires :to, type: Integer, desc: "no desc"
      requires :resolution, type: String, desc: "no desc"
    end
    get "/history" do
      no_data =   {nextTime:0, s:'no_data'}

      trades = get_points_twe(params[:symbol],params[:resolution],params[:from], params[:to])
      unless trades.size == 0
        t,c,o,h,l,v = [],[],[],[],[],[]

        trades.each do |trade|
          trade[1].each do |trade_|
            value = MultiJson.decode(trade_.to_s)

            t << value[0]
            o << value[1]
            h << value[2]
            l << value[3]
            c << value[4]
            v << value[5]
          end
        end

        if t.size > 0
          {t:t,c:c,o:o,h:h,l:l,v:v, s:'ok'}
        else
          no_data
        end
      else
        no_data
      end
    end

  end
end
