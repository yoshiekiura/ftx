class StratumWithdrawProcess

  def process(w,stratum_wallet_id)
    @logger = Logger.new STDOUT


    begin
      Withdraw.transaction do
        withdraw = Withdraw.lock.find(w.id)

        return unless withdraw.almost_done?
        unless withdraw.txout.nil?
          @logger.error "#{ENV['SERVER_TYPE']}:Stratum withdraw already exists operation_id: #{withdraw.txout}"
          return
        end

        currency = Currency.find_by_code(withdraw.currency)
        withdraw.currency[:stratum_wallet_id] = stratum_wallet_id
        currency[:stratum_wallet_id] = stratum_wallet_id

        balance = currency.balance

        if balance < withdraw.sum
          withdraw.reject
          withdraw.save!

          SystemMailer.stratum_balance_none(currency)
          @logger.error "#{ENV['SERVER_TYPE']}:Stratum balance none: #{currency.code}"

          return
        end

        withdraw_stratum = send_crypt(withdraw)

        if withdraw_stratum.nil?
          @logger.error "#{ENV['SERVER_TYPE']}:Stratum event withdraw not found: #{withdraw}"
          withdraw.reject
          withdraw.save!
        else
          stratum_event = save_event(withdraw_stratum)

          withdraw.whodunnit('Worker::WithdrawCoin') do
            withdraw.update_column( :txout, withdraw_stratum[:operation_id] )
            if withdraw_stratum[:operation_status] == 'failed'
              withdraw.reject

              stratum_event.cointrade_state = :failed
              stratum_event.save!
            end
            withdraw.save!
          end
        end

      end

    rescue
      withdraw = Withdraw.lock.find(w.id)
      withdraw.reject
      withdraw.save!

      SystemMailer.stratum_withdraw_error(w, $!.message, $!.backtrace.join("\n"))
      @logger.error "Failed to process: #{$!}"
      @logger.error $!.backtrace.join("\n")
    end

  end

  private

  def send_crypt( withdraw )
    currency = Currency.find_by_code(withdraw.currency)

    data = nil
    payload = { operation_amount: withdraw.amount.to_f,
                operation_otp: '123456', # No OTP at this stage
                operation_desc: "#{currency.code} withdraw",
                dest_address: withdraw.fund_uid,
                operation_eid: withdraw.id,
                wallet_id: currency[:stratum_wallet_id],
    }

    @logger.info "PAYLOAD WITHDRAW: #{payload}"
    response = Stratum::Withdraw.crypto(payload)


    @logger.info "RESPONSE WITHDRAW: #{response.data}"
    data = response.data

    data
  rescue
    SystemMailer.stratum_operation_error(w, $!.message, $!.backtrace.join("\n"))
    @logger = Logger.new STDOUT
    @logger.error "Failed to process: #{$!}"
    @logger.error $!.backtrace.join("\n")
    nil
  end

  def save_event( withdraw )
    withdraw.symbolize_keys!
    operation = StratumEvent.where(operation_id: withdraw[:operation_id]).first
    if operation
      operation.update_attributes( { operation_status: withdraw[:operation_status] } )
    else
      @logger.info "#{ENV['SERVER_TYPE']}:Create StratumEvent Withdraw: #{withdraw}"
      StratumEvent.create!(
          operation_id: withdraw[:operation_id],
          wallet_id: withdraw[:wallet_id],
          operation_amount: withdraw[:operation_amount].to_d,
          operation_tamount: withdraw[:operation_tamount].to_d,
          operation_fee: withdraw[:operation_fee].to_d,
          operation_desc: withdraw[:operation_desc],
          operation_eid: withdraw[:operation_eid],
          operation_etxid: withdraw[:operation_etxid],
          operation_ts: withdraw[:operation_ts],
          operation_upd_ts: withdraw[:operation_upd_ts],
          operation_conf: withdraw[:operation_conf],
          operation_confreq: withdraw[:operation_confreq],
          dest_type_data: withdraw[:dest_type_data],
          operation_info: withdraw[:operation_info],
          currency_usdtrate: withdraw[:currency_usdtrate].to_d,
          operation_status: withdraw[:operation_status],
          operation_type: withdraw[:operation_type],
          wallet_eid: withdraw[:wallet_eid],
          wallet_group_id: withdraw[:wallet_group_id],
          wallet_group_eid: withdraw[:wallet_group_eid],
          wallet_label: withdraw[:wallet_label],
          wallet_type: withdraw[:wallet_type],
          currency: withdraw[:currency],
          currency_unit: withdraw[:currency_unit],
          currency_type: withdraw[:currency_type],
          dest_type: withdraw[:dest_type],
          direction_type: 'out',
          cointrade_state: :waiting )
      operation = StratumEvent.where(operation_id: withdraw[:operation_id]).first
    end
    operation
  end

end