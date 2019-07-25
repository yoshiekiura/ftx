app.controller 'WithdrawHistoryController', ($scope, $stateParams, $http) ->
  ctrl = @
  $scope.predicate = '-id'
  @currency = 'brl'
  @account = Account.findBy('currency', @currency)

  @explorers = [
    {
      type: 'btc'
      url: 'https://www.blockchain.com/pt/btc/tx/'
    }
    {
      type: 'bch'
      url: 'https://blockchair.com/bitcoin-cash/transaction/'
    }
    {
      type: 'btg'
      url: 'https://btgexplorer.com/tx/'
    }
    {
      type: 'dash'
      url: 'https://explorer.dash.org/tx/'
    }
    {
      type: 'eth'
      url: 'https://etherscan.io/tx/'
    }
    {
      type: 'zec'
      url: 'https://explorer.zcha.in/transactions/'
    }
    {
      type: 'dgb'
      url: 'https://digiexplorer.info/tx/'
    }
    {
      type: 'xrp'
      url: 'https://xrpcharts.ripple.com/#/transactions/'
    }
    {
      type: 'smart'
      url: 'https://explorer.smartcash.cc/tx/'
    }
    {
      type: 'ltc'
      url: 'https://blockchair.com/litecoin/transaction/'
    }
    {
      type: 'zcr'
      url: 'https://zcr.ccore.online/transaction/'
    }
    {
      type: 'tusd'
      url: 'https://ethplorer.io/tx/'
    }
  ]

  @newRecord = (withdraw) ->
    if withdraw.aasm_state ==  "submitting" then true else false

  @noWithdraw = ->
    @withdraws.length == 0

  @refresh = ->
    @currency = 'brl'
    ctrl.withdraws = @account.all_withdraws()

    for item_withdraw in ctrl.withdraws
      if item_withdraw.currency != 'brl'
        item_withdraw.title_fund_extra = item_withdraw.fund_extra
      else
        item_withdraw.title_fund_extra = I18n.t("banks."+item_withdraw.fund_extra)
        if(item_withdraw.fund_extra != '_341')
          item_withdraw.fee = item_withdraw.fee - 10.90
          item_withdraw.ted = 10.90
          item_withdraw.total =  item_withdraw.ted + item_withdraw.fee
        else
          item_withdraw.total = item_withdraw.fee

    
    $scope.$apply()

  @canCancel = (state) ->
    ['submitting', 'submitted', 'accepted'].indexOf(state) > -1


  @explore = (txid, currency) ->

    routes = @explorers.filter (x) -> x.type == currency
    route = routes[0].url
    window.open route + txid, '_blank'
    return


  @cancelWithdraw = (withdraw) ->
    withdraw_channel = WithdrawChannel.findBy('currency', withdraw.currency)
    $http.delete("/withdraws/#{withdraw_channel.resource_name}/#{withdraw.id}")
      .error (responseText) ->
        $.publish 'flash', { message: responseText }

  do @event = ->
    ctrl.refresh()
    Withdraw.bind "create update destroy", ->
      ctrl.refresh()
