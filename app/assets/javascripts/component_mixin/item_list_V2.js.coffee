@ItemListMixinV2 = ->
  @attributes
    table_orders: 'div.all-orders'
    allTableSelector: 'div.all-orders'
    askTableSelector: 'div.ask-orders'
    bidTableSelector: 'div.bid-orders'
    tbody: 'div'
    empty: '.empty-row'
    limit: 50

  @checkEmpty = (event, data) ->
    if @select('tbody').find('.order-pair-row').length is 0
      @select('empty').fadeIn()
    else
      @select('empty').fadeOut()

  @addOrUpdateItem = (item, selector) ->

    if selector?
      type_filter = selector.substr(4, 3)
    else
      type_filter = item.kind
      selector = "div." + type_filter + "-orders"

    @.attr.tbody = selector + ' > div.order-pair > div' + '#' + item.market + '-' + type_filter

    template = @getTemplate(item)
    existsItem = @select('tbody').find("div[data-id=#{item.id}][data-kind=#{item.kind}]")

    if existsItem.length
      existsItem.html template.html()
    else
      template.prependTo(@select('tbody')).show('slow')

    $tbody = $(@.attr.tbody)
    $rows = $($tbody.children('div.order-pair-subrows'))
    rows_length = $rows.length

    if ($rows.length - 1) == @.attr.limit
      $(@.attr.tbody + ' div.order-pair-subrows:last').remove();

    rows_length = @select('tbody').find('.order-pair-row').filter(':not([style="display: none;"])').length
    $(selector).find("span[id='count_"+item.market+ '-' + type_filter + "']").html rows_length


    @checkEmpty()

    selector = "div.all-orders"
    type_filter = "all"

    @.attr.tbody = selector + ' > div.order-pair > div' + '#' + item.market + '-' + type_filter
    template = @getTemplate(item)
    existsItem = @select('tbody').find("div[data-id=#{item.id}][data-kind=#{item.kind}]")

    if existsItem.length
      existsItem.html template.html()
    else
      template.prependTo(@select('tbody')).show('slow')

    $tbody = $(@.attr.tbody)
    $rows = $($tbody.children('div.order-pair-subrows'))
    rows_length = $rows.length

    if ($rows.length - 1) == @.attr.limit
      $(@.attr.tbody + ' div.order-pair-subrows:last').remove();

    rows_length = $(@.attr.tbody).find('.order-pair-row').filter(':not([style="display: none;"])').length
    $(@.attr.allTableSelector).find("span[id=count_" + item.market + "-all" + "]").html rows_length
#    $(@.attr.allTableSelector).find("span[id=count_" + order.market + "-all" + "]").html rows_length
    @checkEmpty()

  @removeItem = (order) ->
    type_filter = "all"

    @.attr.tbody = "div.all-orders" + ' > div.order-pair > div' + '#' + order.market + '-' + type_filter
    item = @select('tbody').find("div[data-id=#{order.id}]")
    item.hide 'slow', =>
      item.remove()
      @countOrders(order)
      @checkEmpty()

    @.attr.tbody = 'div.order-pair > div' + '#' + order.market + '-' + order.kind
    item = @select('tbody').find("div[data-id=#{order.id}]")
    item.hide 'slow', =>
      item.remove()
      @countOrders(order)
      @checkEmpty()

  @countOrders = (order) ->
    $('span[id=count_' + order.market + '-all' + ']').html $('#' + order.market + '-all > div:not([style=\'display: none;\']').length
    $('span[id=count_' + order.market + '-bid' + ']').html $('#' + order.market + '-bid > div:not([style=\'display: none;\']').length
    $('span[id=count_' + order.market + '-ask' + ']').html $('#' + order.market + '-ask > div:not([style=\'display: none;\']').length
    return

  @populate = (event, data, selector) ->
    type_filter = selector.substr(0, 3)

    market_quote_unit = gon.market.quote_unit
    tbl = @select(selector)

    for currency of gon.accounts
      currPair = currency + market_quote_unit
      if gon.markets[currPair]
        curr_title = gon.markets[currPair].name

        template2 = @getTemplateMarkets(currPair+'-'+type_filter, curr_title)
        tbl.append(template2)

    if not _.isEmpty(data)
      for item in data
        @addOrUpdateItem item,tbl.selector

      @checkEmpty()


