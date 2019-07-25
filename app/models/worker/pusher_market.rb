module Worker
  require 'newrelic_rpm'

  class PusherMarket
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def process(payload, metadata, delivery_info)
      trade = Trade.new payload
      trade.trigger_notify
      Global[trade.market].trigger_trades [trade.for_global]
    end
      add_transaction_tracer :process, :category => :task
  end
end
