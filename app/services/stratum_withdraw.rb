class StratumWithdraw
	class << self
		def crypt( withdraw )
			currency = Currency.find_by_code(withdraw.currency)

			data = nil
			payload = { operation_amount: withdraw.amount.to_f,
						operation_otp: '123456', # No OTP at this stage
						operation_desc: "#{currency.code} withdraw",
						dest_address: withdraw.fund_uid,
						operation_eid: withdraw.id,
						wallet_id: currency[:stratum_wallet_id],
			}
			response = Stratum::Withdraw.crypto(payload)

			if response.success?
			 data = response.data
			end

			data
		rescue
			SystemMailer.stratum_operation_error(payload, $!.message, $!.backtrace.join("\n"))
			Rails.logger.error "Failed to process: #{$!}"
			Rails.logger.error $!.backtrace.join("\n")
			nil
		end

		def save_event( withdraw )
			withdraw.symbolize_keys!
			operation = StratumEvent.where(operation_id: withdraw[:operation_id]).first
			if operation
				operation.update_attributes( { operation_status: withdraw[:operation_status] } )
			else
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
end
