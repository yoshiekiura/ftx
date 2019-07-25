module Worker
  require 'newrelic_rpm'
  class TradeExecutor
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!
      ::Matching::Executor.new(payload).execute!
    rescue
      SystemMailer.trade_execute_error(payload, $!.message, $!.backtrace.join("\n")).deliver
      raise $!
    end
      add_transaction_tracer :process, :category => :task
  end
end
