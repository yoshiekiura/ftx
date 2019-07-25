window.MarketTradesUI = flight.component ->
  flight.compose.mixin @, [NotificationMixin]

  @attributes
    defaultHeight: 156
    tradeSelector: 'tr'
    newTradeSelector: 'tr.new'
    allSelector: 'a.all'
    mySelector: 'a.my'
    allTableSelector: 'table.all-trades tbody'
    myTableSelector: 'table.my-trades tbody'
    newMarketTradeContent: 'table.all-trades tr.new div'
    newMyTradeContent: 'table.my-trades tr.new div'
    tradesLimit: 20

  @showAllTrades = (event) ->
    @select('mySelector').removeClass('active')
    @select('allSelector').addClass('active')
    @select('myTableSelector').hide()
    @select('allTableSelector').show()

  @showMyTrades = (event) ->
    @select('allSelector').removeClass('active')
    @select('mySelector').addClass('active')
    @select('allTableSelector').hide()
    @select('myTableSelector').show()

  @bufferMarketTrades = (event, data) ->
    @marketTrades = @marketTrades.concat data.trades

  @clearMarkers = (table) ->
    table.find('tr.new').removeClass('new')
    table.find('tr').slice(@attr.tradesLimit).remove()

  @notifyMyTrade = (trade) ->
    market = gon.markets[trade.market]
    message = gon.i18n.notification.new_trade
      .replace(/%{kind}/g, gon.i18n[trade.kind])
      .replace(/%{id}/g, trade.id)
      .replace(/%{price}/g, trade.price)
      .replace(/%{volume}/g, trade.volume)
      .replace(/%{base_unit}/g, market.base_unit.toUpperCase())
      .replace(/%{quote_unit}/g, market.quote_unit.toUpperCase())
    @notify message

  @isMine = (trade) ->
    return false if @myTrades.length == 0

    for t in @myTrades
      if trade.tid == t.id
        return true
      if trade.tid > t.id # @myTrades is sorted reversely
        return false

  @handleMarketTrades = (event, data) ->

    @trades = data.trades.slice(0, @attr.tradesLimit).reverse()
    for trade in @trades
      diff = trade.price - @last_value

      percent = Math.abs(((trade.price / @last_value) - 1 ) * 100)

      if percent > 100
        percent = 100

      if percent > 0 and percent <=25
        trade.variationColor = 'lower'
      else if percent >=26 and percent <=50
        trade.variationColor = 'low'
      else if percent >=51 and percent <=75
        trade.variationColor = 'medium'
      else
        trade.variationColor = 'high'

      if diff == 0
        el = @select('allTableSelector').prepend(JST['templates/market_trade_same'](trade))
      else if diff > 0
        el = @select('allTableSelector').prepend(JST['templates/market_trade_up'](trade))
      else
        el = @select('allTableSelector').prepend(JST['templates/market_trade_down'](trade))

      @last_value = trade.price
      @marketTrades.unshift trade
      trade.classes = 'new'
      trade.classes += ' mine' if @isMine(trade)

    @marketTrades = @marketTrades.slice(0, @attr.tradesLimit)
    @select('newMarketTradeContent').slideDown('fast')

    setTimeout =>
      @clearMarkers(@select('allTableSelector'))
    , 900

  @handleMyTrades = (event, data, notify=true) ->
    @myTrades = data.trades.slice(0, @attr.tradesLimit)
    for trade in data.trades
      if trade.market == gon.market.id
        @myTrades.unshift trade
        trade.classes = 'new'
        el = @select('myTableSelector').prepend(JST['templates/my_trade'](trade))
        @select('allTableSelector').find("tr#market-trade-#{trade.id}").addClass('mine')

      @notifyMyTrade(trade) if notify

    @myTrades = @myTrades.slice(0, @attr.tradesLimit) if @myTrades.length > @attr.tradesLimit
    @select('newMyTradeContent').slideDown('fast')

    setTimeout =>
      @clearMarkers(@select('myTableSelector'))
    , 900

  @after 'initialize', ->
    @marketTrades = []
    @myTrades = []
    @last_value = 0

    @on document, 'trade::populate', (event, data) =>
      @handleMyTrades(event, trades: data.trades.reverse(), false)
    @on document, 'trade', (event, trade) =>
      @handleMyTrades(event, trades: [trade])

    @on document, 'market::trades', (event, data) =>
      @handleMarketTrades(event, trades: data.trades.reverse())

    @on @select('allSelector'), 'click', @showAllTrades
    @on @select('mySelector'), 'click', @showMyTrades
