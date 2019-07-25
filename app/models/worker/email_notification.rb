module Worker
  require 'newrelic_rpm'

  class EmailNotification
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def process(payload, metadata, delivery_info)
      @logger = Logger.new STDOUT

      payload.symbolize_keys!
      set_locale(payload)

      mailer = payload[:mailer_class].constantize
      action = payload[:method]
      args   = payload[:args]

      message = mailer.send(:new, action, *args).message
      message.deliver

    rescue ActiveRecord::RecordNotFound => e
      # Wait for MySQL buffer
      sleep 30

      @logger.info "Retrying notification #{payload[:mailer_class].inspect}"

      message = mailer.send(:new, action, *args).message
      message.deliver
    rescue
      SystemMailer.notification_error(payload, $!.message, $!.backtrace.join("\n")).deliver
      @logger.error "Failed to notify: #{$!}"
      @logger.error $!.backtrace.join("\n")
    end

    private

    def set_locale(payload)
      locale = payload[:locale]
      I18n.locale = locale if locale
    end
      add_transaction_tracer :process, :category => :task
  end
end
