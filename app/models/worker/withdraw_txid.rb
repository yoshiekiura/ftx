module Worker
  #require 'newrelic_rpm'
  class WithdrawTxid
      #include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    class DryrunError < StandardError


      def initialize()

      end
    end


    def initialize(options={})
      withdraws_cached = Rails.cache.instance_variable_get(:@data).keys("peatio:withdraw:*:*:data")
      withdraws_cached.each do | key |
        withdraw_temp = Rails.cache.read(key)
        sleep 1
        AMQPQueue.enqueue(:withdraw_txid, withdraw_temp.as_json, {persistent: true})
      end
    end

    def process(payload, metadata, delivery_info)
        @payload = payload

        payload.symbolize_keys!
        puts "SAIDA PAYLOAD: #{payload.inspect}"

        create_thread_and_notify(payload)
      rescue
      @logger.fatal "Failed to process: #{$!}"
      @logger.fatal $!.backtrace.join("\n")
    end

    def create_thread_and_notify(payload)
      Thread.new do
        withdraw_txid_data = get_data(payload)

        while check_state(withdraw_txid_data.aasm_state)

          puts "Pega COIN: #{withdraw_txid_data.currency.upcase} "
          puts "Pega fund_uid: #{withdraw_txid_data.fund_uid} "
          puts "Pega hora atual: #{Time.now} "
          puts "Pega data inicial withdraw: #{withdraw_txid_data.created_at}"
          puts "Pega Status: #{withdraw_txid_data.aasm_state}"

          diff = Time.now - withdraw_txid_data.created_at

          puts "Pega diferenca: #{diff} "
          puts "SAIDA TESTE = Coin: #{withdraw_txid_data.currency.upcase} \n  Internal ID : #{withdraw_txid_data.id} \n Type: Withdraw \n TXID: #{withdraw_txid_data.fund_uid} := Condition:"

          if (0...3600) === diff
            sleep_remain = 3600 - diff
            puts "Entrou stage 1 diff : #{diff}  Pega sleep_remain: #{sleep_remain}"
            withdraw_txid_state = 1
          elsif (3708...7200) === diff
            sleep_remain = 7200 - diff
            withdraw_txid_state = 2
            puts "Entrou stage 2 diff : #{diff}  Pega sleep_remain: #{sleep_remain}"
          elsif (7308...10800) === diff
            sleep_remain = 10800 - diff
            withdraw_txid_state = 3
            puts "Entrou stage 3 diff : #{diff}  Pega sleep_remain: #{sleep_remain}"
          else
            sleep_remain = 14400
            withdraw_txid_state = 4
            puts "Entrou stage 4 diff : #{diff}  Pega sleep_remain: #{sleep_remain}"
          end

          sleep sleep_remain
          withdraw_txid_data = get_data(payload)

          case withdraw_txid_state
          when 1
            puts "Entrou when stage 1 "
            puts "SAIDA 1 = Coin: #{withdraw_txid_data.currency.upcase} \n  Internal ID : #{withdraw_txid_data.id} \n Type: Withdraw \n TXID: #{withdraw_txid_data.fund_uid} := Condition: <=  #{withdraw_txid_state} hour"
            notify(withdraw_txid_data, withdraw_txid_state)
            Rails.cache.write "peatio:withdraw:#{withdraw_txid_data.fund_uid}:#{withdraw_txid_data.currency}:state", 1
          when 2
            puts "Entrou when stage 2 "
            puts "SAIDA 2 = Coin: #{withdraw_txid_data.currency.upcase} \n  Internal ID : #{withdraw_txid_data.id} \n Type: Withdraw \n TXID: #{withdraw_txid_data.fund_uid} := Condition: <=  #{withdraw_txid_state} hour"
            notify(withdraw_txid_data, withdraw_txid_state)
            Rails.cache.write "peatio:withdraw:#{withdraw_txid_data.fund_uid}: #{withdraw_txid_data.currency}:state", 2
          when 3
            puts "Entrou when stage 3 "
            puts "SAIDA 3 = Coin: #{withdraw_txid_data.currency.upcase} \n  Internal ID : #{withdraw_txid_data.id} \n Type: Withdraw \n TXID: #{withdraw_txid_data.fund_uid} := Condition: <=  #{withdraw_txid_state} hour"
            notify(withdraw_txid_data, withdraw_txid_state)
            Rails.cache.write "peatio:withdraw:#{withdraw_txid_data.fund_uid}: #{withdraw_txid_data.currency}:state", 3
          else
            puts "SAIDA 4 = Coin: #{withdraw_txid_data.currency.upcase} \n  Internal ID : #{withdraw_txid_data.id} \n Type: Withdraw \n TXID: #{withdraw_txid_data.fund_uid} := Condition: <=  #{withdraw_txid_state} hour"
            puts "Entrou when stage 4 "
            notify(withdraw_txid_data, withdraw_txid_state)
            Rails.cache.write "peatio:withdraw:#{withdraw_txid_data.fund_uid}: #{withdraw_txid_data.currency}:state", 4
          end
        end
        Rails.cache.delete("peatio:withdraw:#{withdraw_txid_data.fund_uid}:#{withdraw_txid_data.currency}:data")
        Rails.cache.delete("peatio:withdraw:#{withdraw_txid_data.fund_uid}:#{withdraw_txid_data.currency}:state",1)
        Rails.cache.delete("peatio:withdraw:#{withdraw_txid_data.fund_uid}:#{withdraw_txid_data.currency}:state",2)
        Rails.cache.delete("peatio:withdraw:#{withdraw_txid_data.fund_uid}:#{withdraw_txid_data.currency}:state",3)
        Rails.cache.delete("peatio:withdraw:#{withdraw_txid_data.fund_uid}:#{withdraw_txid_data.currency}:state",4)
        Thread.exit
      end

    end

    def get_data(withdraw)
      Rails.cache.read("peatio:withdraw:#{withdraw[:fund_uid]}:#{withdraw[:currency]}:data")
    end

    def get_state(withdraw)
      Rails.cache.read("peatio:withdraw:#{withdraw[:fund_uid]}:#{withdraw[:currency]}:state")
    end

    def check_state(aasm_state)
      unless aasm_state == 'accepted' or aasm_state == 'cancelled' or aasm_state == 'rejected' or aasm_state == 'suspect' or aasm_state == 'failed' or aasm_state == 'done' or aasm_state == 'rejected'
         true
      else
        false
      end
    end

    def notify(withdraw, level)

      client_details={}
      client_details[:title] = "Stratum operation warned:"
      client_details[:pretext] = "NOTICE:Stratum operation type withdraw"
      client_details[:text] = "Coin: #{withdraw.currency.upcase} \n  Internal ID : #{withdraw.id} \n Type: Withdraw \n TXID: #{withdraw.fund_uid} := Condition: <=  #{level} hour"



      begin
        if ENV['NOTIFICATION_SEND_SYSTEM'] == 'Y'
          send_notification_api_stratum(client_details,level)
        end
      rescue
        puts "Fail send Notifications"
      end


    end

=begin
    def send_notification_api_sumary(client_details,level)
      require 'nokogiri'
      data = {}

      data[:level] = 'warn'
      data[:channels] = ['slack','telegram','ceo']
      data[:app] = 'Cointrade Exchange'
      data[:realm] = ENV['SERVER_TYPE']
      data[:message] = client_details
      data

      result = RestClient.post(
          ENV['NOTIFICATIONS_API'],
          data.as_json,
          {
              content_type: 'application/json',
              Authorization: ENV['NOTIFICATIONS_API_PWD64']

          }
      )

    rescue Exception => exception
      return result.inspect, exception.message

    end
=end

    def send_notification_api_stratum(client_details,level)
      require 'nokogiri'
      data = {}

      data[:level] = 'warn'
      puts "Entrou level=  #{level} "

      if level == 4
        data[:channels] = ['slack','ceo']
      else
        data[:channels] = ['slack','telegram']
      end

      data[:app] = 'Cointrade Exchange'
      data[:realm] = ENV['SERVER_TYPE']
      data[:message] = client_details
      data

      result = RestClient.post(
          ENV['NOTIFICATIONS_API'],
          data.as_json,
          {
              content_type: 'application/json',
              Authorization: ENV['NOTIFICATIONS_API_PWD64']

          }
      )

    rescue Exception => exception
      return result.inspect, exception.message

    end


=begin
     add_transaction_tracer :process, :category => :task
     add_transaction_tracer :create_thread_and_notify, :category => :task
     add_transaction_tracer :get_data, :category => :task
     add_transaction_tracer :get_state, :category => :task
     add_transaction_tracer :notify, :category => :task
=end



  end
end
