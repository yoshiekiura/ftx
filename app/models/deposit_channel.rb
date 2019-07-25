class DepositChannel < ActiveYamlBase
  include Channelable
  include HashCurrencible
  include International
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  def accounts
    bank_accounts.map {|i| OpenStruct.new(i) }
  end

  def as_json(options = {})
    super(options)['attributes'].merge({resource_name: key.pluralize})
  end
  # add_transaction_tracer :accounts,
  #                        :name => 'accounts',
  #                        :category => "DepositChannel/accounts"
  # add_transaction_tracer :as_json,
  #                        :name => 'as_json',
  #                        :category => "DepositChannel/as_json"
end
