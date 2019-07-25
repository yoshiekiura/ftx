namespace :sync_balance do
  desc "Sync all balances and remove duplicated values from deposits: Step 1"
  task sync_all_step_one: :environment do

    puts "Cancel all orders"
    Rake::Task["order_manager:cancel_all_orders"].invoke

    puts "Delete all deposits where currency != 1"
    Deposit.delete_all "currency != 1"

    puts "Delete all stratum_event of deposits"
    StratumEvent.delete_all "operation_type = 'deposit'"

    puts "Delete all payment_transactions"
    PaymentTransaction.delete_all

    puts "Delete all account_versions log"
    AccountVersion.delete_all "modifiable_type = 'Deposit'"

    puts "Set all balances and locke to 0 where currency != 1"
    Account.where("currency != 1").update_all(:balance => 0, :locked =>0)

    puts "Clear cache timestamp to reprocess stratum_events operations deposit"

    Currency.all.each do | currency |
      Rails.cache.write("stratum:deposits:last_ts:#{currency.code}",0)
    end

    puts "Step one done, please wait stratum_events at sync all deposits and after run step 2"

  end

  desc "Sync all balances and remove duplicated values from deposits: Step 2"
  task sync_all_step_two: :environment do
    puts "Sync trades ..."
    Account.all.each do | acc |
        balance = acc.balance
        sum_ask = Trade.where("currency = ? and ask_member_id = ?", acc['currency'], acc.member_id).group('ask_member_id').sum('volume')
        sum_bid = Trade.where("currency = ? and bid_member_id = ?", acc['currency'], acc.member_id).group('bid_member_id').sum('volume')


          if sum_bid[acc.member_id].blank? or sum_bid.nil?
            sum_bid[acc.member_id] = 0
          end

          if sum_ask[acc.member_id].blank? or sum_ask.nil?
            sum_ask[acc.member_id] = 0
          end
          total = balance + sum_bid[acc.member_id] - sum_ask[acc.member_id]
          if total < 0
            puts "Total negativo member_id: #{acc.member_id}  currency: #{acc.currency}"
            puts "Balance #{balance}"
            puts "Trade bid: #{sum_bid[acc.member_id]}"
            puts "trade ask: #{sum_ask[acc.member_id]}"
          else
            acc.balance = total
            acc.save
          end

    end
    puts "Sync trades Done!"

    puts "Sync withdraws ..."
    Account.all.each do | acc |

      balance = acc.balance
      sum_withdraw = Withdraw.where("currency = ? and member_id = ? and txid is not null", acc['currency'], acc.member_id).group('account_id').sum('sum')
      if sum_withdraw[acc.id].blank? or sum_withdraw.nil?
        sum_withdraw[acc.id] = 0
      end
      total = balance - sum_withdraw[acc.id]
      if total < 0
        puts "Total negativo member_id: #{acc.member_id}  currency: #{acc.currency}"
        puts "Balance #{balance}"
        puts "Sum withdraws: #{sum_withdraw[acc.id]}"
        acc.balance = 0
        acc.save
      else
        acc.balance = total
        acc.save
      end

    end
    puts "Sync withdraws Done!"


  end

end
