module Worker
  require 'newrelic_rpm'

  class StratumDeposit
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def initialize(currency)
      @currency = currency
      @logger = Logger.new STDOUT
    end

    # Check wallets by coin
    def process
      StratumOperation.deposits(@currency).each do |deposit|
        deposit.symbolize_keys!

        operation = StratumEvent.where(operation_etxid: deposit[:operation_etxid]).first
        if operation
          puts "Update attributes in StratumEvents TXID: #{deposit[:operation_etxid]}"
          operation.update_attributes( { operation_status: deposit[:operation_status] } )
        else
          if StratumEvent.create!(
              operation_id: deposit[:operation_id],
              wallet_id: deposit[:wallet_id],
              operation_amount: deposit[:operation_amount].to_d,
              operation_tamount: deposit[:operation_tamount].to_d,
              operation_fee: deposit[:operation_fee].to_d,
              operation_desc: deposit[:operation_desc],
              operation_eid: deposit[:operation_eid],
              operation_etxid: deposit[:operation_etxid],
              operation_ts: deposit[:operation_ts],
              operation_upd_ts: deposit[:operation_upd_ts],
              operation_conf: deposit[:operation_conf],
              operation_confreq: deposit[:operation_confreq],
              dest_type_data: deposit[:dest_type_data],
              operation_info: deposit[:operation_info],
              currency_usdtrate: deposit[:currency_usdtrate].to_d,
              operation_status: deposit[:operation_status],
              operation_type: deposit[:operation_type],
              wallet_eid: deposit[:wallet_eid],
              wallet_group_id: deposit[:wallet_group_id],
              wallet_group_eid: deposit[:wallet_group_eid],
              wallet_label: deposit[:wallet_label],
              wallet_type: deposit[:wallet_type],
              currency: deposit[:currency],
              currency_unit: deposit[:currency_unit],
              currency_type: deposit[:currency_type],
              dest_type: deposit[:dest_type],
              direction_type: deposit[:direction_type],
              cointrade_state: :waiting )

            # Update milestone
            puts "Add deposit in StratumEvents TXID: #{deposit[:operation_etxid]}"
            StratumOperation.refresh_deposit_last_ts(@currency, deposit[:operation_upd_ts].to_i)
          end
        end

        # Send to Message Broker
        payload = { txid: deposit[:operation_etxid],
                    txout: deposit[:operation_id],
                    channel_key: @currency.code }
        attrs   = { persistent: true }
        AMQPQueue.enqueue(:deposit_coin, payload, attrs)
      end
    rescue
      @logger.fatal "Failed to process: #{$!}"
      @logger.fatal $!.backtrace.join("\n")
    end
      add_transaction_tracer :process, :category => :task

  end
end
