class DepositSlip extends PeatioModel.Model
  @configure 'DepositSlip', 'person_name','person_doc','phone','email','postal_code','city','state','address_number','address_name','address_complement'

  constructor: ->
    super

  @initData: (records) ->
    PeatioModel.Ajax.disable ->
      $.each records, (idx, record) ->
        DepositSlip.create(record)
