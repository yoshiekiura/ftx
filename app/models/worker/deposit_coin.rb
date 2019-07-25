module Worker
  require 'newrelic_rpm'

  class DepositCoin
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      sleep 0.5 # nothing result without sleep by query gettransaction api

      channel_key = payload[:channel_key]
      txid = payload[:txid]
      txout = payload[:txout]

      channel = DepositChannel.find_by_key(channel_key)

      ActiveRecord::Base.transaction do
        raw     = get_raw_from_db(channel, txid, txout)

        unless raw.empty?
          raw[:details].each_with_index do |detail, i|
            detail.symbolize_keys!
            deposit!(channel, txid, txout, raw, detail)
          end
        end

      end
    end

    def deposit!(channel, txid, txout, raw, detail)
      return false if detail[:account] != "payment" || detail[:category] != "receive"

      operation = StratumEvent.where(operation_etxid: txid).first

      unless PaymentAddress.where(currency: detail[:currency], address: detail[:address]).first
        # puts "Deposit address not found, skip. txid: #{txid}, txout: #{txout}, address: #{detail[:address]}, amount: #{detail[:amount]}"
        operation.cointrade_state = :failed
        operation.save!
        return false
      end

      if PaymentTransaction::Normal.where(txid: txid, txout: txout).first
        # puts "Payment already been taken, skip. txid: #{txid}, txout: #{txout}, address: #{detail[:address]}, amount: #{detail[:amount]}"
        unless operation.cointrade_state == :done
          operation.cointrade_state = :done
          operation.save!
        end
        return false
      end

      tx = PaymentTransaction::Normal.create! \
        txid: txid,
        txout: txout,
        address: detail[:address],
        amount: detail[:amount].to_s.to_d,
        confirmations: raw[:confirmations],
        receive_at: Time.at(raw[:timereceived]).to_datetime,
        currency: detail[:currency]

      deposit = channel.kls.create! \
        payment_transaction_id: tx.id,
        txid: tx.txid,
        txout: tx.txout,
        amount: tx.amount,
        member: tx.member,
        account: tx.account,
        currency: tx.currency,
        confirmations: tx.confirmations
      deposit.submit!

      puts "Setting cointrade_state DONE, txid: #{txid}, txout: #{txout}, address: #{detail[:address]}, amount: #{detail[:amount]}"
      operation.cointrade_state = :done
      operation.save!

      return true
    rescue
      puts "Failed to deposit: #{$!}"
      puts "txid: #{txid}, txout: #{txout}, detail: #{detail.inspect}"
      puts $!.backtrace.join("\n")
    end

    def get_raw(channel, txid)
      channel.currency_obj.api.gettransaction(txid)
    end

    def get_raw_from_db(channel, txid, txout)
      operation = StratumEvent.where(operation_etxid: txid, operation_id: txout).first
      raw = {}
      if operation
        raw = { amount:operation.operation_amount,
                confirmations:channel.max_confirm, # Already confirmed by Stratum node
                txid:txid,
                txout:txout,
                time:Time.now.to_i,
                timereceived:operation.operation_ts,
                details: [{"account":"payment",
                           "address": MultiJson.decode( operation.dest_type_data )['wallet_address'],
                           "category":"receive",
                           "currency":operation.wallet_eid,
                           "amount":operation.operation_amount}],
                hex: ''}

        operation.cointrade_state = :processing
        operation.save!
      end

      raw
    end
      add_transaction_tracer :process, :category => :task
      add_transaction_tracer :deposit!, :category => :task
      add_transaction_tracer :get_raw_from_db, :category => :task
      add_transaction_tracer :get_raw, :category => :task
  end
end