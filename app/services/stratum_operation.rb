class StratumOperation
	class << self

		def deposits(currency)
			@logger = Logger.new STDOUT
			deposits = []
			begin
				payload = { wallet_eid: currency.id,
										operation_type: 'deposit',
										operation_upd_ts_from: last_ts(currency),
										operation_upd_ts_to: Time.now.to_i,
										destination_type: :address,
										operation_status: 'done'
				}
				@logger.info "PAYLOAD: #{payload}"
				response = Stratum::Operation.list(payload)
				if response.success? and response.has_key?('operation_id',true) and response.data.size > 0

					deposits = response.data

				end
				@logger.info "#{currency.code} deposits size #{deposits.size}"
				
				deposits
			rescue
				SystemMailer.stratum_operation_error(payload, $!.message, $!.backtrace.join("\n"))
				@logger.error "Failed to process: #{$!}"
				@logger.error $!.backtrace.join("\n")
				deposits
			end
		end

		def withdraw_fee(currency_code)
			@logger = Logger.new STDOUT
			fee = 0
			payload = { currency: currency_code.upcase,
						operation_type: :withdraw,
						dest_type: :address
			}

			response = Stratum::Operation.fees(payload)
			if response.success? and response.has_key?('operation_fee',true)
			fee = response.data[0]['operation_fee'].to_d
			end
			fee
		rescue
			@logger.error "Failed to process: #{$!}"
			@logger.error $!.backtrace.join("\n")
			0
		end

		def refresh_deposit_last_ts(currency, ts)
			update_last_ts(currency,ts) if ts > last_ts(currency)
		end

		private

		def key_for(currency)
			"stratum:deposits:last_ts:#{currency.code}"
		end

		def last_ts(currency)
			Rails.cache.read(key_for(currency)) || 0
		end

		def update_last_ts(currency,ts)
			Rails.cache.write(key_for(currency), ts)
		end

	end
end
