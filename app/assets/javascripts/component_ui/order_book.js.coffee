@OrderBookUI = flight.component ->
  @attributes
    bookLimit: 25
    askBookSel: 'tbody.asks'
    bidBookSel: 'tbody.bids'
    seperatorSelector: 'table.seperator'
    fade_toggle_depth: '#fade_toggle_depth'
    major_total: 0

  @update = (event, data) ->
    @updateOrders(@select('bidBookSel'), _.first(data.bids, @.attr.bookLimit), 'bid')
    @updateOrders(@select('askBookSel'), _.first(data.asks, @.attr.bookLimit), 'ask')

  @appendRow = (book, template, data) ->
    data.classes = 'new'
    book.append template(data)

  @insertRow = (book, row, template, data) ->
    data.classes = 'new'
    row.before template(data)

  @updateRow = (row, order, index, v1, v2) ->
    row.data('order', index)
    return if v1.equals(v2)

    if v2.greaterThan(v1)
      row.addClass('text-up')
    else
      row.addClass('text-down')

    row.data('count', order[1][0])
    row.data('volume', order[1][1])
    row.data('total', order[2])
    row.find('td.count').html(formatter.mask_fixed_count(order[1][0]))
    row.find('td.volume').html(formatter.mask_fixed_volume(order[1][1]))
    row.find('td.total').html(formatter.mask_fixed_volume(order[2]))

  @mergeUpdate = (bid_or_ask, book, orders, template) ->
    rows = book.find('tr')
    i = j = 0
    while(true)
      row = rows[i]
      order = orders[j]
      $row = $(row)
      if order
        rows.remove()
        percent = parseInt((order[2] * 100) / @.attr.major_total)

        @appendRow(book, template,
          price: order[0], count: order[1][0],volume: order[1][1], total: order[2], index: j, background: percent)
        j += 1
      else
        rows.remove()
        break

  @clearMarkers = (book) ->

    book.find('tr.new').removeClass('new')
    book.find('tr.text-up').removeClass('text-up')
    book.find('tr.text-down').removeClass('text-down')

    obsolete = book.find('tr.obsolete')
    obsolete_divs = book.find('tr.obsolete div')
    #obsolete_divs.slideUp 'slow', ->
    obsolete.remove()

  @updateOrders = (table, orders, bid_or_ask) ->

    orders = @computeTotal(orders)
    book = @select("#{bid_or_ask}BookSel")
    @mergeUpdate bid_or_ask, book, orders, JST["templates/order_book_#{bid_or_ask}"]

  @computeDeep = (event, orders) ->
    index      = Number $(event.currentTarget).data('order')
    orders     = _.take(orders, index + 1)
    volume_fun = (memo, num) -> memo.plus(BigNumber(num[1]))
    volume     = _.reduce(orders, volume_fun, BigNumber(0))
    price      = BigNumber(_.last(orders)[0])
    origVolume = _.last(orders)[1][1]
    {price: price, volume: volume, origVolume: origVolume}

  @computeTotal = (orders) ->
    total = 0
    for order in orders
      total += Number(order[1][1])
      if(@.attr.major_total < total)
        @.attr.major_total = total
      order.push total.toString()
    orders

  @placeOrder = (target, data) ->
      @trigger target, 'place_order::input::price', data
      @trigger target, 'place_order::input::volume', data

  @after 'initialize', ->
    @on document, 'market::order_book::update', @update

    @on @select('fade_toggle_depth'), 'click', =>
      @trigger 'market::depth::fade_toggle'

    $('.asks').on 'click', 'tr', (e) =>
      i = $(e.target).closest('tr').data('order')
      @placeOrder $('#bid_entry'), {price: BigNumber(gon.asks[i][0]).toFixed(2), volume: formatter.mask_fixed_volume_round(gon.asks[i][2])}
      @placeOrder $('#ask_entry'), {price: BigNumber(gon.asks[i][0]).toFixed(2), volume: formatter.mask_fixed_volume_round(gon.asks[i][2])}

    $('.bids').on 'click', 'tr', (e) =>
      i = $(e.target).closest('tr').data('order')
      @placeOrder $('#ask_entry'), {price: BigNumber(gon.bids[i][0]).toFixed(2), volume: formatter.mask_fixed_volume_round(gon.bids[i][2])}
      @placeOrder $('#bid_entry'), {price: BigNumber(gon.bids[i][0]).toFixed(2), volume: formatter.mask_fixed_volume_round(gon.bids[i][2])}
