module Worker
  require 'newrelic_rpm'
  class PusherMember
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def process(payload, metadata, delivery_info)
      member = Member.find payload['member_id']
      event  = payload['event']
      data   = JSON.parse payload['data']
      member.notify event, data
    end
      add_transaction_tracer :process, :category => :task
  end
end
