module Worker
  require 'newrelic_rpm'

  class SamuraiDeposit
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def initialize(deposit)
      @deposit = deposit
      @logger = Logger.new STDOUT
    end

    def process
      @logger.debug "Check deposit #{@deposit.txid}"
      return if @deposit.txid.nil?

      _type, _document, _samurai_code, samurai_id = @deposit.txid.split(':')
      response = Samurai::Order.status(samurai_id)

       # lock second by day if waiting
      if response.is_a?(Samurai::Response)

        case response.status
        when :not_found
          @logger.debug "NotFound/Cancelled deposit #{@deposit.txid}"
          @deposit.reject_it!(@deposit.txid)

        when :ok
          if response.data[:done]

            # Parse and set decimal format with 2 places
            samurai_amount = sprintf("%.2f",response.data[:amount_confirmed].to_d)
            cointrade_amount = sprintf("%.2f",@deposit.amount.to_d)

            if response.data[:bank_confirmed] and
                samurai_amount == cointrade_amount
              @logger.debug "Accepted deposit #{@deposit.txid}"
              @deposit.charge!(@deposit.txid)
            else
              @logger.debug "Rejected deposit #{@deposit.txid}"
              @deposit.reject_it!(@deposit.txid)
            end
          end
        end

      else
        @logger.warn "Samurai weird response: #{response.inspect}"
      end

    end
      add_transaction_tracer :process, :category => :task
  end
end
