module Worker
  require 'newrelic_rpm'
  class StratumWithdraw
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def initialize(currency)
      @currency = currency
      @logger = Logger.new STDOUT
    end

    # Check withdraw by coin
    def process
      by_time_batch
      by_waiting_batch
    rescue
      @logger.fatal "Failed to process: #{$!}"
      @logger.fatal $!.backtrace.join("\n")
    end

    private

    def by_time_batch
      withdraws_updated_list.each do |withdraw_stratum|

        withdraw_stratum.symbolize_keys!
        operation = StratumEvent.where(operation_id: withdraw_stratum[:operation_id]).first

        if operation.nil?
          SystemMailer.stratum_withdraw_error(operation, 'DB empty', {})
          Rails.logger.error "Stratum withdraw not found inside DB: #{operation.inspect}"
        else
          if operation and operation.cointrade_state != 'done'

            ActiveRecord::Base.transaction do
              update_operation(operation, withdraw_stratum)
              case withdraw_stratum[:operation_status]
              when 'done'
                make_withdraw_succeed(operation, withdraw_stratum)
                update_milestone(withdraw_stratum[:operation_upd_ts].to_i)
              when 'failed'
                make_withdraw_failed(operation, withdraw_stratum)
              end
            end
          end
        end

      end
    rescue
      @logger.fatal "Failed to process: #{$!}"
      @logger.fatal $!.backtrace.join("\n")
    end

    def by_waiting_batch
      StratumEvent.where(wallet_id:@currency[:stratum_wallet_id]).
            with_cointrade_state(:processing, :waiting).each do |operation|

        withdraw_stratum = get_withdraw_stratum_info(operation)

        if withdraw_stratum.nil?
          SystemMailer.stratum_withdraw_error(operation, 'API empty', {})
          Rails.logger.error "Stratum withdraw not found inside API: #{operation.inspect}"
        else

          withdraw_stratum.symbolize_keys!
          ActiveRecord::Base.transaction do
            update_operation(operation, withdraw_stratum)
            case withdraw_stratum[:operation_status]
            when 'done'
              make_withdraw_succeed(operation, withdraw_stratum)
            when 'failed'
              make_withdraw_failed(operation, withdraw_stratum)
            end
          end

        end
      end
    end

    def make_withdraw_succeed( operation, withdraw_stratum )
      withdraw_peatio = Withdraw.lock.find_by_txout(withdraw_stratum[:operation_id])
      if withdraw_peatio
        withdraw_peatio.whodunnit('Worker::StratumWithdraw') do
          withdraw_peatio.txid = withdraw_stratum[:operation_etxid]
          withdraw_peatio.succeed
          withdraw_peatio.save!

          operation.cointrade_state = :done
          operation.save!
        end
      end
    end

    def make_withdraw_failed( operation, withdraw_stratum )
      withdraw_peatio = Withdraw.lock.find_by_txout(withdraw_stratum[:operation_id])
      if withdraw_peatio
        withdraw_peatio.whodunnit('Worker::StratumWithdraw') do
          withdraw_peatio.txid = withdraw_stratum[:operation_etxid]
          withdraw_peatio.reject
          withdraw_peatio.save!

          operation.cointrade_state = :failed
          operation.save!
        end
      end
    end

    def update_operation( operation, withdraw_stratum )
      operation.update_attributes( { operation_id: withdraw_stratum[:operation_id],
                                     operation_amount: withdraw_stratum[:operation_amount].to_d,
                                     operation_tamount: withdraw_stratum[:operation_tamount].to_d,
                                     operation_fee: withdraw_stratum[:operation_fee].to_d,
                                     operation_desc: withdraw_stratum[:operation_desc],
                                     operation_eid: withdraw_stratum[:operation_eid],
                                     operation_etxid: withdraw_stratum[:operation_etxid],
                                     operation_ts: withdraw_stratum[:operation_ts],
                                     operation_upd_ts: withdraw_stratum[:operation_upd_ts],
                                     operation_conf: withdraw_stratum[:operation_conf],
                                     operation_confreq: withdraw_stratum[:operation_confreq],
                                     operation_info: withdraw_stratum[:operation_info],
                                     currency_usdtrate: withdraw_stratum[:currency_usdtrate].to_d,
                                     operation_status: withdraw_stratum[:operation_status],
                                   } )
    end

    def withdraws_updated_list
      deposits = []
      begin
        response = Stratum::Operation.list({ wallet_id: @currency[:stratum_wallet_id],
                                             operation_type: 'withdraw',
                                             operation_upd_ts_from: last_ts,
                                             operation_upd_ts_to: Time.now.to_i,
                                             destination_type: :address,
                                           })
        if response.success? and response.data.size > 0
          deposits = response.data
        end
        @logger.info "#{@currency.code} withdraws size #{deposits.size}"

        deposits
      rescue
        SystemMailer.stratum_operation_error(payload, $!.message, $!.backtrace.join("\n"))
        @logger.error "Failed to process: #{$!}"
        @logger.error $!.backtrace.join("\n")
        deposits
      end
    end

    def get_withdraw_stratum_info(operation)
      info = nil
      begin
        response = Stratum::Operation.list({ operation_eid: operation.operation_eid,
                                             operation_type: 'withdraw',
                                             destination_type: :address,
                                           })
        if response.success? and response.data.size > 0
          info = response.data[0]
          @logger.info "#{@currency.code} withdraw eid #{operation.operation_eid} status #{info['operation_status']}"
        end

        info
      rescue
        SystemMailer.stratum_operation_error(payload, $!.message, $!.backtrace.join("\n"))
        @logger.error "Failed to process: #{$!}"
        @logger.error $!.backtrace.join("\n")
        deposits
      end
    end

    def key_for
      "stratum:withdraws:last_ts:#{@currency.code}"
    end

    def update_milestone(ts)
      update_last_ts(ts) if ts > last_ts
    end

    def last_ts
      Rails.cache.read(key_for) || 0
    end

    def update_last_ts(ts)
      Rails.cache.write(key_for, ts)
    end

     add_transaction_tracer :process, :category => :task
     add_transaction_tracer :by_waiting_batch, :category => :task
     add_transaction_tracer :make_withdraw_succeed, :category => :task
     add_transaction_tracer :make_withdraw_failed, :category => :task
     add_transaction_tracer :update_operation, :category => :task
     add_transaction_tracer :withdraws_updated_list, :category => :task
     add_transaction_tracer :key_for, :category => :task
     add_transaction_tracer :update_milestone, :category => :task
     add_transaction_tracer :last_ts, :category => :task
     add_transaction_tracer :update_last_ts, :category => :task

  end
end
