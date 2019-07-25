namespace :stratum_withdraw_event_manager do
  desc "Process one withdraw and send to stratum API"
  task process_withdraw_by_id: :environment do

    if ENV['WITHDRAW_ID'].blank?
      puts "Please inform the param WITHDRAW_ID"
      exit 0

    else if ENV['STRATUM_WALLET_ID'].blank?
        puts "Please inform the param STRATUM_WALLET_ID"
        exit 0
    else
      puts "FIND WITHDRAW"
      withdraw_process = StratumWithdrawProcess.new
      withdraw = Withdraw.find(ENV['WITHDRAW_ID'])
      puts withdraw.inspect
    end

      begin
        puts "START PROCESS"
        withdraw_process.process(withdraw,ENV['STRATUM_WALLET_ID'])
      rescue StandardError => e
        puts "Rescued: #{e.inspect}"
      end
    end
  end


  desc "Cancel withdraw"
  task cancel_withdraw_by_id: :environment do

    if ENV['WITHDRAW_ID'].blank?
      puts "Please inform the param WITHDRAW_ID"
      exit 0
    else
      puts "FIND WITHDRAW"
      withdraw = Withdraw.find(ENV['WITHDRAW_ID'])
      if withdraw.txout.nil?
        withdraw.reject!
        withdraw.save!
        puts "Withdraw rejected with success!#{withdraw}"

      else
        puts "Withdraw can't rejected because is processing by Stratum!#{withdraw}"
        puts "Operation ID in Stratum: #{withdraw.txout}"
      end

    end
  end

end
