window.MarketListTickersUI = flight.component ->
  @attributes
    table: 'tbody'
    marketGroupName: '.panel-body-head thead span.name'
    marketGroupItem: '.dropdown-wrapper .dropdown-menu li a'
    marketsTable: '.table.markets'

  @switchMarketGroup = (event, item) ->
    item = $(event.target).closest('a')
    name = item.data('name')

    @select('marketGroupItem').removeClass('active')
    item.addClass('active')

    @select('marketGroupName').text item.find('span').text()
    @select('marketsTable').attr("class", "table table-hover markets #{name}")

  @updateMarket = (select, ticker) ->
    trend = formatter.trend ticker.last_trend

    select.find('td.last')
      .attr('title', ticker.last)
      .html( ticker.last)

    select.find('td.vol')
      .attr('title', ticker.volume)
      .html( ticker.volume)

    p1 = parseFloat(ticker.open)
    p2 = parseFloat(ticker.last)
    trend = formatter.trend(p1 <= p2)
    select.find('td.change').html("<span class='#{trend}'>#{formatter.price_change(p1, p2)}%</span>")

  @refresh = (event, data) ->
    table = @select('table')
    for ticker in data.tickers
      @updateMarket table.find("tr#market-list-#{ticker.market}"), ticker.data

    table.find("tr#market-list-#{gon.market.id}").addClass 'highlight'

  @after 'initialize', ->
    @on document, 'market::tickers', @refresh
    @on @select('marketGroupItem'), 'click', @switchMarketGroup

    @.hide_accounts = $('tr.hide')
    $('.view_all_accounts').on 'click', (e) =>
      $el = $(e.currentTarget)
      if @.hide_accounts.hasClass('hide')
        $el.text($el.data('hide-text'))
        @.hide_accounts.removeClass('hide')
      else
        $el.text($el.data('show-text'))
        @.hide_accounts.addClass('hide')
