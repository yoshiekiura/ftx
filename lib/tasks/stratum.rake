namespace :stratum do

  task test: :environment do
    Stratum.logger.level = Logger::DEBUG

    # begin
			# response = Stratum::Wallet.list({})
			# puts Time.now.to_i
			# puts "status = #{response.status}"
			# puts JSON.pretty_generate(response.data)
    #
    # rescue
    #   puts "Failed to process: #{$!}"
			# Rails.logger.error "Failed to process: #{$!}"
			# Rails.logger.error $!.backtrace.join("\n")
    # end


    response = Stratum.time()
    puts Time.now.to_i
    puts "status = #{response.status}"
    puts JSON.pretty_generate(response.data)
    #
    # payload = { #wallet_eid: 25,
    #             currency: 'btc'.upcase,
    #             wallet_type: 'checking'
    # }
    # puts JSON.pretty_generate(payload)
    # response = Stratum::Wallet.list(payload)
    # puts Time.now.to_i
    # puts "status = #{response.status}"
    # puts JSON.pretty_generate(response.data)

    # payload = { currency: 'btc'.upcase,
    #             #wallet_type: 'checking'
    # }
    # puts JSON.pretty_generate(payload)
    # response = Stratum::Address.list(payload)
    # puts Time.now.to_i
    # puts "status = #{response.status}"
    # puts JSON.pretty_generate(response.data)

    # payload = { wallet_group_eid: 1,
    #             wallet_group_label: 'test btc'
    # }
    # puts JSON.pretty_generate(payload)
    # response = Stratum::WalletGroup.create(payload)
    # puts "status = #{response.status}"
    # puts JSON.pretty_generate(response.data)
    #
    # payload = { wallet_group_eid: 1
    # }
    # puts JSON.pretty_generate(payload)
    # response = Stratum::WalletGroup.list(payload)
    # puts "status = #{response.status}"
    # puts JSON.pretty_generate(response.data)
    #
    # payload = { currency: 'btc'.upcase,
    #             wallet_eid: 1,
    #             wallet_group_id: 4,
    #             wallet_label: 'test btc',
    #             wallet_type: 'checking'
    # }
    # puts JSON.pretty_generate(payload)
    # response = Stratum::Wallet.create(payload)
    # puts Time.now.to_i
    # puts "status = #{response.status}"
    # puts JSON.pretty_generate(response.data)

    #
    # begin
			# response = Stratum::Wallet.list({ wallet_eid: 2 })
			# puts Time.now.to_i
			# puts "status = #{response.status}"
			# puts JSON.pretty_generate(response.data)
    #
    # response = Stratum::Wallet.get({ wallet_id: 40 })
    # puts Time.now.to_i
    # puts "status = #{response.status}"
    # puts JSON.pretty_generate(response.data)
    # #
    # rescue
		 #  Rails.logger.error "Failed to process: #{$!}"
		 #  Rails.logger.error $!.backtrace.join("\n")
    # end
		# response = Stratum::Address.assign({ wallet_id: 10,
		# 																		 id: 1,
		# 																		 label: "testing"
		# 																	 })
		# puts Time.now.to_i
		# puts "response = #{response.inspect}"
		# puts "status = #{response.status}"
		# puts "success? = #{response.success?}"
		# puts "data = #{response.data}"

    # begin
			# response = Stratum::Address.list({ wallet_id: 25,
			# 																					id: 1 })
			# puts Time.now.to_i
			# puts "status = #{response.status}"
			# puts "data = #{response.data}"
			# puts JSON.pretty_generate(response.data)
    # rescue
			# Rails.logger.error "Failed to process: #{$!}"
			# Rails.logger.error $!.backtrace.join("\n")
    # end
    #
    # Currency.all.each do |currency|
			# if currency.coin
			# 	begin
			# 		response = Stratum::Address.list({ wallet_id: currency.stratum_wallet_id })
			# 		puts Time.now.to_i
			# 		puts "status = #{response.status}"
			# 		puts "data = #{response.data}"
			# 		puts JSON.pretty_generate(response.data)
			# 	rescue
			# 		Rails.logger.error "Failed to process: #{$!}"
			# 		Rails.logger.error $!.backtrace.join("\n")
    #     end
			# end
    # end

		# response = Stratum::Transaction.list({ wallet_id: 10,
		# 																	 id: 1 })
		# puts Time.now.to_i
		# puts "response = #{response.inspect}"
		# puts "status = #{response.status}"
		# puts "success? = #{response.success?}"
		# puts "data = #{response.data}"
    #
		# response = Stratum::Operation.list({ wallet_id: 10 })
		# puts Time.now.to_i
		# puts "response = #{response.inspect}"
		# puts "status = #{response.status}"
		# puts "success? = #{response.success?}"
		# puts "data = #{response.data}"

		# response = Stratum::Operation.send_to_address({ wallet_id: 10,
		# 																								address: "2NBexPP8nACXdAnWdbb2mmgBFM4dbLFcndc",
		# 																								amount: 10,
		# 																								description: 'test only',
		# 																								auth: '123456'
		# 																							})
		# puts Time.now.to_i
		# puts "response = #{response.inspect}"
		# puts "status = #{response.status}"
		# puts "success? = #{response.success?}"
		# puts "data = #{response.data}"

		# response = Stratum::Operation.deposit({ wallet_id: 10 })
		# puts Time.now.to_i
		# puts "response = #{response.inspect}"
		# puts "status = #{response.status}"
		# puts "success? = #{response.success?}"
		# puts "data = #{response.data}"

		# response = Stratum::Operation.list({ wallet_id: 10 })
		# puts Time.now.to_i
		# puts "status = #{response.status}"
		# puts "data = #{response.data}"
		# puts JSON.pretty_generate(response.data)

    # begin
			# response = Stratum::Operation.list({ wallet_id: 40,
    #                                        operation_type: 'deposit' })
			# puts Time.now.to_i
			# puts "status = #{response.status}"
			# puts "data = #{response.data}"
			# puts JSON.pretty_generate(response.data)
    # rescue
			# Rails.logger.error "Failed to process: #{$!}"
			# Rails.logger.error $!.backtrace.join("\n")
    # end
    #
    Currency.all.each do |currency|
			if currency.coin
					response = Stratum::Operation.list({
																								 wallet_id: currency.stratum_wallet_id,
                                                 operation_type: :deposit,
																								 #operation_status: :done,
																								 #operation_ts_from: 1532637844,
																								 #operation_upd_ts_from: 1532639644,
																								 #operation_upd_ts_to: Time.new.to_i,
																								 #operation_ts_to: Time.new.to_i,
																								 #operation_direction: "in",
																								 destination_type: :address,
																								 #operation_eid: 0,
																								 #wallet_eid: 2,
																								 #wallet_group_eid: 1
                                             })
					puts Time.now.to_i
					puts "status = #{response.status}"
					puts JSON.pretty_generate(response.data)
			end
    end


    Currency.all.each do |currency|
      if currency.coin
        currency.refresh_balance
        puts "#{currency.code} balance DB #{currency.balance}, balance API #{StratumWallet.get_balance(currency.stratum_wallet_id)}, withdraw_fee #{currency.withdraw_fee}, wallet_id #{currency.stratum_wallet_id}"
      end
    end
    #

  end
end