class Account extends PeatioModel.Model
  @configure 'Account', 'member_id', 'currency', 'balance', 'locked', 'created_at', 'updated_at', 'in', 'out', 'deposit_address', 'name_text'

  @initData: (records) ->
    PeatioModel.Ajax.disable ->
      $.each records, (idx, record) ->
          Account.create(record)

  deposit_channels: ->
    DepositChannel.findAllBy 'currency', @currency

  withdraw_channels: ->
    WithdrawChannel.findAllBy 'currency', @currency

  deposit_channel: ->
    DepositChannel.findBy 'currency', @currency

  deposits: ->
    _.sortBy(Deposit.findAllBy('account_id', @id), (d) -> d.id).reverse()

  all_deposits: ->

    array_deposits = Deposit.findAllBy('member_id', @member_id);

    for item_deposit in array_deposits
      item_deposit.currency_name = item_deposit.currency

    _.sortBy(array_deposits, (d) -> d.id).reverse()

  withdraws: ->
    _.sortBy(Withdraw.findAllBy('account_id', @id), (d) -> d.id).reverse()


  all_withdraws: ->
    _.sortBy(Withdraw.findAllBy('member_id', @member_id));

  topDeposits: ->
    @deposits().reverse().slice(0,3)

  topWithdraws: ->
    @withdraws().reverse().slice(0,3)

window.Account = Account
