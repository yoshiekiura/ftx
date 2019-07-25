app.controller 'DepositHistoryController', ($scope, $stateParams, $http) ->
  ctrl = @
  limit_rows = 3
  $scope.predicate = '-id'

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

  @newRecord = (deposit) ->
    if deposit.aasm_state == "submitting" then true else false

  @noDeposit = ->
    @deposits.length == 0

  @refresh = ->
    @currency = 'brl'
    
    @account = Account.findBy('currency', @currency)
    @deposits = @account.all_deposits()


    for item_deposit in @deposits
      item_deposit.original_txid = item_deposit.txid
      if item_deposit.fund_uid != null and item_deposit.fund_uid.indexOf('Deposits::Slips::') != -1
        item_deposit.title = I18n.t("payment_slip.click_slip")
        item_deposit.txid = I18n.t("funds.deposit_history.slip_type")
      else if item_deposit.currency_name != 'brl'
        item_deposit.title = item_deposit.txid
        item_deposit.fund_extra = item_deposit.blockchain_url
        item_deposit.txid = ''
      else
        item_deposit.txid = item_deposit.txid.substring 0,3
        item_deposit.title = I18n.t("banks."+item_deposit.fund_extra)
        item_deposit.fund_extra = "#"

    $scope.$apply

  @cancelDeposit = (deposit) ->
    deposit_channel = DepositChannel.findBy('currency', deposit.currency)
    $http.delete("/deposits/#{deposit_channel.resource_name}/#{deposit.id}")
      .error (responseText) ->
        $.publish 'flash', { message: responseText }


  @explore = (txid, currency) ->

    routes = @explorers.filter (x) -> x.type == currency
    route = routes[0].url

    window.open route + txid, '_blank'
    return


  @canCancel = (state) ->
    ['submitting'].indexOf(state) > -1

  do @event = ->
    ctrl.refresh()
    Deposit.bind "create update destroy", ->
      ctrl.refresh()
