app.directive 'accounts', ->
  return {
    restrict: 'E'
    templateUrl: '/templates/funds/accounts.html'
    scope: { localValue: '=accounts' }
    controller: ($scope, $rootScope, $state) ->
      ctrl = @
      @state = $state
      # Might have a better way
      # #/deposits/brl
      @selectedCurrency = window.location.hash.split('/')[2] || Account.first().currency
      @currentAction = window.location.hash.split('/')[1] || 'deposits'
      $scope.currency = @selectedCurrency
      $rootScope.currentAction = @currentAction
      if window.location.hash == ""
        @state.transitionTo(@currentAction+".currency", {currency: Account.first().currency})
      else
        ctrl.state.transitionTo(@currentAction+".currency", {currency: @selectedCurrency})
        ctrl.selectedCurrency = @selectedCurrency

      $scope.accounts = Account.all()

      for acc in $scope.accounts
        if acc.currency != 'brl'
          acc.maintenance = gon.markets[acc.currency+'brl'].maintenance

      @isSelected = (currency) ->
        @selectedCurrency == currency

      @isDeposit = ->
        @currentAction == 'deposits'

      @isWithdraw = ->
        @currentAction == 'withdraws'

      @deposit = (account) ->
        console.log 'deposit clicked...'
        ctrl.state.transitionTo("deposits.currency", {currency: account.currency})
        ctrl.selectedCurrency = account.currency

        $('#qrcode-'+account.deposit_address).qrcode(account.deposit_address)

        ctrl.currentAction = "deposits"

        $ () ->

          i = 0
          setTimeout (->
            while $('#qrcode-'+account.deposit_address).children().length > 1
              $('#qrcode-'+account.deposit_address).children()[1].remove()
          ), 500
          

        


      @withdraw = (account) ->
        ctrl.state.transitionTo("withdraws.currency", {currency: account.currency})
        ctrl.selectedCurrency = account.currency
        ctrl.currentAction = "withdraws"

      do @event = ->
        Account.bind "create update destroy", ->
          $scope.$apply()

    controllerAs: 'accountsCtrl'
  }

