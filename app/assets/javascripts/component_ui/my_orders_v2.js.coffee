@MyOrdersV2UI = flight.component ->
  flight.compose.mixin @, [ItemListMixinV2]


  @attributes
    allSelector: 'a.all-orders-view'
    askSelector: 'a.ask'
    bidSelector: 'a.bid'
    allTableSelector: 'div.all-orders'
    askTableSelector: 'div.ask-orders'
    bidTableSelector: 'div.bid-orders'

  @getTemplate = (order) -> $(JST["templates/order_active_v2"](order: order, market_pair: gon.markets[order.market].name, cancel: I18n.t("cancel")))


  @getTemplateMarkets = (market_id, curr_title) -> $(JST["templates/markets_accordions"](market_id: market_id, curr_title: curr_title))

  @showAllOrders = (event) ->
    @select('askSelector').removeClass('active')
    @select('bidSelector').removeClass('active')
    @select('allSelector').addClass('active')
    @populate(event, @allOrders)

  @showAskOrders = (event) ->
    @select('allSelector').removeClass('active')
    @select('bidSelector').removeClass('active')
    @select('askSelector').addClass('active')
    @populate(event, @askOrders)

  @showBidOrders = (event) ->
    @select('allSelector').removeClass('active')
    @select('askSelector').removeClass('active')
    @select('bidSelector').addClass('active')
    @populate(event, @bidOrders)

  @triggerUpdate = (event) ->
    @trigger 'market::order_book::update'

  @orderHandler = (event, order) ->
    #return unless order.market == gon.market.id
    #console.log order
    switch order.state
      when 'wait'
        @addOrUpdateItem order
      when 'cancel'
        @removeItem order
      when 'done'
        @removeItem order

  @orderPopulate = (event, order) ->
    @allOrders = order
    @askOrders.push ord for ord in order.orders when ord.kind == 'ask'
    @bidOrders.push ord for ord in order.orders when ord.kind == 'bid'

    @populate(event, @allOrders.orders, 'allTableSelector')
    @populate(event, @askOrders, 'askTableSelector')
    @populate(event, @bidOrders, 'bidTableSelector')


  @.after 'initialize', ->
    @allOrders = []
    @askOrders = []
    @bidOrders = []

    @on document, 'order::wait::populate', (event, data) =>
      @orderPopulate(event, data)
    @on document, 'order::wait order::cancel order::done', @orderHandler

    $ ->
      $('.order-pair-header').click ->
        $(this).children().toggleClass 'open'
        orderPairSubrows = $(this).parent().find('.order-pair-subrows')
        if !orderPairSubrows.hasClass('open')
          orderPairSubrows.addClass 'open'
        else
          orderPairSubrows.removeClass 'open'
        return


      $('a.all-orders-view').on 'click', (e) => @showAllOrders(e)

      @showAllOrders = (event) ->
        $('a.ask').removeClass('active')
        $('a.bid').removeClass('active')
        $('a.all-orders-view').addClass('active')
        $('div.ask-orders').hide()
        $('div.bid-orders').hide()
        $('div.all-orders').show()

      $('a.ask').on 'click', (e) => @showAskOrders(e)

      @showAskOrders = (event) ->
        $('a.all-orders-view').removeClass('active')
        $('a.bid').removeClass('active')
        $('a.ask').addClass('active')
        $('div.all-orders').hide()
        $('div.bid-orders').hide()
        $('div.ask-orders').show()

      $('a.bid').on 'click', (e) => @showBidOrders(e)

      @showBidOrders = (event) ->
        $('a.all-orders-view').removeClass('active')
        $('a.ask').removeClass('active')
        $('a.bid').addClass('active')
        $('div.all-orders').hide()
        $('div.ask-orders').hide()
        $('div.bid-orders').show()


      @showUpdateOrder = (id) ->
        $.ajax
          url: formatter.market_url gon.market.id, id
          method: 'get'
          success: (data, textStatus, jqXHR) ->
            $("#price").val(data.price)
            $("#amount").val(data.volume)
            $(".modal-currency").html(data.ask.toUpperCase())

            $('#update_order').attr('data-id', data.id)
            $('#update_order').attr('onclick', 'updateOrder('+data.id+')')
            $("#modal_order").modal()
          error: ->
            $("#modal_order").modal('hide')

      @deleteOrder = (id) ->
        $.ajax
          url: formatter.market_url gon.market.id, id
          method: 'delete'
          success: ->
            @triggerUpdate
        $("#modal_order").modal('hide')