class WithdrawChannel < ActiveYamlBase
  #require 'newrelic_rpm'
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  include Channelable
  include HashCurrencible
  include International

  def blacklist
    self[:blacklist]
  end

  def as_json(options = {})
    super(options)['attributes'].merge({resource_name: key.pluralize})
  end
  # add_transaction_tracer :blacklist,
  #                        :name => 'blacklist?',
  #                        :category => "WithdrawChannel/blacklist?"
end
