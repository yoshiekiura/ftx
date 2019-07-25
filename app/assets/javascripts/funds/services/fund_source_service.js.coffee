app.service 'fundSourceService', ['$filter', '$gon', '$resource', 'accountService', ($filter, $gon, $resource, accountService) ->

  resource = $resource '/fund_sources/:id',
    {id: '@id'}
    {update: { method: 'PUT' }}

  filterBy: (filter) ->
    for fs in $gon.fund_sources
      uid_split = fs.uid.split('/')
      cpf = uid_split[0]
      agency = uid_split[1]
      account = uid_split[2]
      accountDigit = uid_split[3]
      fs.cpf = cpf
      fs.agency = agency
      fs.account = account
      fs.accountDigit = accountDigit
    $filter('filter')($gon.fund_sources, filter)

  findBy: (filter) ->
    result = @filterBy filter
    if result.length then result[0] else null

  defaultFundSource: (filter) ->
    account = accountService.findBy filter
    return null if not account
    @findBy id: account.default_withdraw_fund_source_id

  create: (data, afterCreate) ->
    resource.save data, (fund_source) =>
      $gon.fund_sources.push fund_source
      afterCreate(fund_source) if afterCreate

  update: (fund_source, afterUpdate) ->
    # Change default_withdraw_fund_source_id immediately,
    # Do not wait for server side response
    account = accountService.findBy currency:fund_source.currency
    return null if not account
    account.default_withdraw_fund_source_id = fund_source.id

    resource.update id: fund_source.id, =>
      afterUpdate() if afterUpdate

  remove: (fund_source, afterRemove) ->
    resource.remove id: fund_source.id, =>
      $gon.fund_sources.splice $gon.fund_sources.indexOf(fund_source), 1
      afterRemove() if afterRemove

]
