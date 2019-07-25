class AMQPQueue
  #require 'newrelic_rpm'


  class <<self
    # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    def connection
      @connection ||= Bunny.new(AMQPConfig.connect,:automatic_recovery => true).tap do |conn|
        conn.start
      end
    end

    def channel
      @channel ||= connection.create_channel
    end

    def exchanges
      @exchanges ||= {default: channel.default_exchange, durable: true}
    end

    def exchange(id)
      exchanges[id] ||= channel.send *AMQPConfig.exchange(id)
    end

    def publish(eid, payload, attrs={})
      payload = JSON.dump payload

      attrs[:persistent] = true
      delay = AMQPConfig.delay(eid)
      sleep(delay) unless delay.nil?
      exchange(eid).publish(payload, attrs)
    end

    def queue_exists? queue_name
      
      conn = !connection.nil? rescue false
      
      if conn
        if connection.queue_exists?(queue_name)
          true
        else 
          false
        end
      else
        false
      end
      
    end

    # enqueue = publish to direct exchange
    def enqueue(id, payload, attrs={})
      eid = AMQPConfig.binding_exchange_id(id) || :default
      payload.merge!({locale: I18n.locale})
      attrs.merge!({routing_key: AMQPConfig.routing_key(id)})
      publish(eid, payload, attrs)
    end

    # add_transaction_tracer :connection,
    #                        :name => 'connection',
    #                        :category => "AMQPQueue/connection"
    # add_transaction_tracer :channel,
    #                        :name => 'channel',
    #                        :category => "AMQPQueue/channel"
    # add_transaction_tracer :exchanges,
    #                        :name => 'exchanges',
    #                        :category => "AMQPQueue/exchanges"
    # add_transaction_tracer :exchange,
    #                        :name => 'exchange',
    #                        :category => "AMQPQueue/exchange"
    # add_transaction_tracer :publish,
    #                        :name => 'publish',
    #                        :category => "AMQPQueue/publish"
    # add_transaction_tracer :enqueue,
    #                        :name => 'enqueue',
    #                        :category => "AMQPQueue/enqueue"
  end

  module Mailer
    class <<self
      def included(base)
        base.extend(ClassMethods)
      end

      def excluded_environment?(name)
        [:test].include?(name.try(:to_sym))
      end
    end

    module ClassMethods

      def method_missing(method_name, *args)
        if action_methods.include?(method_name.to_s)
          MessageDecoy.new(self, method_name, *args)
        else
          super
        end
      end

      def deliver?
        true
      end
    end

    class MessageDecoy
      # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      delegate :to_s, :to => :actual_message

      def initialize(mailer_class, method_name, *args)
        @mailer_class = mailer_class
        @method_name = method_name
        *@args = *args
        actual_message if environment_excluded?
      end

      def environment_excluded?
        #ActionMailer::Base.add_delivery_method(:mailgun, Mailgun, default_options={})
        !ActionMailer::Base.perform_deliveries || ::AMQPQueue::Mailer.excluded_environment?(Rails.env)
      end

      def actual_message
        @actual_message ||= @mailer_class.send(:new, @method_name, *@args).message
      end

      def deliver
        return deliver! if environment_excluded?

        if @mailer_class.deliver?
          begin
            AMQPQueue.enqueue(:email_notification, mailer_class: @mailer_class.to_s, method: @method_name, args: @args)
          rescue
            Rails.logger.error "Unable to enqueue :mailer: #{$!}, fallback to synchronous mail delivery"
            deliver!
          end
        end
      end

      def deliver!
        actual_message.deliver
      end

      def method_missing(method_name, *args)
        actual_message.send(method_name, *args)
      end
      # add_transaction_tracer :initialize,
      #                        :name => 'initialize',
      #                        :category => "AMQPQueue/initialize"
      # add_transaction_tracer :environment_excluded?,
      #                        :name => 'environment_excluded?',
      #                        :category => "AMQPQueue/environment_excluded?"
      # add_transaction_tracer :actual_message,
      #                        :name => 'actual_message',
      #                        :category => "AMQPQueue/actual_message"
      # add_transaction_tracer :actual_message,
      #                        :name => 'actual_message',
      #                        :category => "AMQPQueue/actual_message"
    end
  end

end
