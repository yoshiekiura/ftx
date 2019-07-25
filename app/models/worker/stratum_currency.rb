module Worker
  require 'newrelic_rpm'
  class StratumCurrency
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def initialize
      @logger = Logger.new STDOUT
    end

    # Check wallets by currency
    def process
      info = []

      Currency.all.each do |currency|
        if currency.coin
          group_id = StratumWalletGroup.get_id(1, 'cointrade')

          # Check locally
          if currency[:stratum_wallet_id].nil? or currency[:stratum_wallet_id] == 0

            # Load from api, or create
            wallet_eid = StratumWallet.get_id(currency.id, group_id, currency)

            if wallet_eid.nil?
              @logger.error "Failed loading/creating wallet #{currency.code}"
            else
              # Update Redis
              currency.update_stratum_wallet_id(wallet_eid)
            end
          end

          #Update currencies memory list
          info << "#{currency.code} group #{group_id} stratum_wallet_id = #{currency.stratum_wallet_id}"
        end
      end
      @logger.info "Define Stratum wallets: #{JSON.pretty_generate(info)} "
    rescue
      SystemMailer.wallet_mapping_error({}, $!.message, $!.backtrace.join("\n"))
      @logger.error "Failed to map: #{$!}"
      @logger.error $!.backtrace.join("\n")
    end
      add_transaction_tracer :process, :category => :task
  end
end
