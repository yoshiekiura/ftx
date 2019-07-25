module APIv2
  class Trades < Grape::API
    helpers ::APIv2::NamedParams

    desc 'Get recent trades on market, each trade is included only once. Trades are sorted in reverse creation order.'
    params do
      use :trade_filters
      optional :market, default: 'btcbrl'
    end
    get "/trades" do
      #Cointrade alteracao para tratamento sellside buyside bitvalor linha abaixo comentada substituida pela debaixo desfeito
      trades = Trade.filter(params[:market], time_to, params[:from], params[:to], params[:limit], order_param)
      #trades = Trade.filter(params[:market], time_to, params[:from], params[:to], params[:limit], order_param, params[:originator])
      present trades, with: APIv2::Entities::Trade
    end

    desc 'Get your executed trades. Trades are sorted in reverse creation order.', scopes: %w(history)
    params do
      use :auth, :market, :trade_filters
    end
    get "/trades/my" do
      authenticate!

      trades = Trade.for_member(
        params[:market], current_user,
        limit: params[:limit], time_to: time_to,
        from: params[:from], to: params[:to],
        order: order_param
      )

      present trades, with: APIv2::Entities::Trade, current_user: current_user
    end

  end
end
