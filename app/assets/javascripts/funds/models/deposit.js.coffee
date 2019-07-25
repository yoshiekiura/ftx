class Deposit extends PeatioModel.Model
  @configure 'Deposit', 'account_id', 'member_id', 'currency', 'amount', 'fee', 'fund_uid', 'fund_extra',
    'blockchain_url', 'state', 'aasm_state', 'created_at', 'updated_at', 'done_at', 'type', 'payment_transaction_id', 'confirmations', 'is_submitting', 'txid_desc', 'txid_by_user', 'txout', 'txid'

  constructor: ->
    super
    @is_submitting = @aasm_state == "submitting"

  @initData: (records) ->
    PeatioModel.Ajax.disable ->
      $.each records, (idx, record) ->
        Deposit.create(record)

window.Deposit = Deposit



