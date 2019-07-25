@AccountBalanceUI = flight.component ->
  @updateAccount = (event, data) ->
    for currency, account of data

      fixed = 2
      for id, market of gon.markets
        if market.base_unit == currency
          if currency == 'brl'
             fixed = 2
          else if currency =='xrp'
             fixed = 6
          else
             fixed = 8

      total =account.balance
      @$node.find(".account.#{currency} span.balance").text "#{formatter.round total, fixed}"

  @after 'initialize', ->
    @on document, 'account::update', @updateAccount
