class StratumWalletGroup
	class << self
		# include NewRelic::Agent::Instrumentation::ControllerInstrumentation
		def get_id(eid, key_name)
			Rails.logger.info "Check Stratum wallet group eid #{eid}, key_name #{key_name}"

			group_eid = local_id(key_name)
			unless group_eid
			# Load from api, or create
			group_eid = check_eid(eid)
			group_eid = generate_eid(eid, key_name) if group_eid.nil?

			if group_eid.nil?
				Rails.logger.error "Failed creating wallet group eid #{eid}, key_name #{key_name}"
				raise StandardError.new( "Failed creating wallet group eid #{eid}, key_name #{key_name}")
			else
				# Update Redis
				update_local_id(key_name,group_eid)
			end
			end
			group_eid
		end

		private

		def check_eid(eid)
			id = nil
			payload = { wallet_group_eid: eid }

			response = Stratum::WalletGroup.list(payload)
			if response.success? and response.has_key?('wallet_group_id',true)
			id = response.data[0]['wallet_group_id'].to_i
			end
			id
		rescue
			SystemMailer.wallet_mapping_error(payload, $!.message, $!.backtrace.join("\n"))
			Rails.logger.error "Failed to process: #{$!}"
			Rails.logger.error $!.backtrace.join("\n")
			nil
		end

		def generate_eid(eid, key_name)
			id = nil
			payload = { wallet_group_eid: eid,
						wallet_group_label: key_name
			}

			response = Stratum::WalletGroup.create(payload)
			if response.success? and response.has_key?('wallet_group_id',false)
			id = response.data['wallet_group_id'].to_i
			else
			SystemMailer.wallet_mapping_error(payload, response.message, response.inspect)
			end
			id
		rescue
			SystemMailer.wallet_mapping_error(payload, $!.message, $!.backtrace.join("\n"))
			Rails.logger.error "Failed to process: #{$!}"
			Rails.logger.error $!.backtrace.join("\n")
			nil
		end

		private

		def key_for(key_name)
			"stratum:#{key_name}:wallet_group_id"
		end

		def local_id(key_name)
			Rails.cache.read(key_for(key_name)) || nil
		end

		def update_local_id(key_name, id)
			Rails.cache.write(key_for(key_name), id)
		end
		# add_transaction_tracer :get_id,
		# 											 :name => 'get_id',
		# 											 :category => "StratumOperation/get_id"
		# add_transaction_tracer :check_eid,
		# 											 :name => 'check_eid',
		# 											 :category => "StratumOperation/check_eid"
		# add_transaction_tracer :generate_eid,
		# 											 :name => 'generate_eid',
		# 											 :category => "StratumOperation/generate_eid"
		# add_transaction_tracer :key_for,
		# 											 :name => 'key_for',
		# 											 :category => "StratumOperation/key_for"
		# add_transaction_tracer :local_id,
		# 											 :name => 'local_id',
		# 											 :category => "StratumOperation/local_id"
		# add_transaction_tracer :update_local_id,
		# 											 :name => 'update_local_id',
		# 											 :category => "StratumOperation/update_local_id"

	end
end
