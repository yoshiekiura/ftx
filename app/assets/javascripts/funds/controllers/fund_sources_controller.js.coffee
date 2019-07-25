app.controller 'FundSourcesController', ['$scope', '$gon', 'fundSourceService', '$window', ($scope, $gon, fundSourceService, $window) ->

  $scope.banks = $gon.banks
  $scope.currency = currency = $scope.ngDialogData.currency

  str_url = $window.location.href
  console.log str_url

  $scope.verifyUrl = ->
    if str_url.includes('deposit')
      true
    else
      false

  $scope.fund_sources = ->
    fundSourceService.filterBy currency:currency

  $scope.defaultFundSource = ->
    fundSourceService.defaultFundSource currency:currency

  $scope.addAdressBank = ->

    return false if $scope.validar() == false
    cpf = $scope.cpf
    agency = $scope.agency
    account = $scope.account
    dig = $scope.dig

    uid = cpf + '/' + agency + '/' + account + '/' + dig
    extra = $scope.extra.trim() if angular.isString($scope.extra)

    return if not uid
    return if not extra

    data = uid: uid, extra: extra, currency: currency
    fundSourceService.create data, ->
      $scope.uid = ""
      $scope.extra = "" if currency isnt $gon.fiat_currency
      $scope.cpf = ""
      $scope.agency = ""
      $scope.account = ""
      $scope.dig = ""

  $scope.addAdressCoin = ->
    uid   = $scope.uid.trim()   if angular.isString($scope.uid)
    extra = $scope.extra.trim() if angular.isString($scope.extra)

    return if not uid
    return if not extra

    data = uid: uid, extra: extra, currency: currency
    fundSourceService.create data, ->
      $scope.uid = ""
      $scope.extra = "" if currency isnt $gon.fiat_currency

  $scope.remove = (fund_source) ->
    fundSourceService.remove fund_source

  $scope.makeDefault = (fund_source) ->
    fundSourceService.update fund_source


  $scope.validar = ->
    cpf = if $scope.cpf != "" then $scope.cpf else 0
    agency = if $scope.agency != "" then $scope.agency else 0
    account = if $scope.account != "" then $scope.account else 0
    dig = if $scope.dig != "" then $scope.dig else 0

    if cpf == 0 || agency == 0 || account == 0 || dig == 0
      alert I18n.t('fund_sources.manage_bank_account_required')
      return false

]
