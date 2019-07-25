module Worker
  require 'newrelic_rpm'
  class DepositTxid
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation


    class DryrunError < StandardError


      def initialize()

      end
      
    end


    def initialize(options={})
      deposits_cached = Rails.cache.instance_variable_get(:@data).keys("peatio:deposit:*:*:data")
      deposits_cached.each do | key |
        deposit_temp = Rails.cache.read(key)
        sleep 1
        AMQPQueue.enqueue(:deposit_txid, deposit_temp.as_json, {persistent: true})
      end
    end

    def process(payload, metadata, delivery_info)
      @payload = payload

      payload.symbolize_keys!

      puts payload.inspect

      create_thread_and_notify(payload)

    end

    def create_thread_and_notify(payload)
      Thread.new do
        deposit_txid_data = get_data(payload)

        while check_state(deposit_txid_data.aasm_state)
          diff = Time.now - deposit_txid_data.created_at
          if (1...20) === diff
            sleep_remain = 20 - diff
            deposit_txid_state = 1
          elsif (21...40) === diff
            sleep_remain = 40 - diff
            deposit_txid_state = 2
          elsif (41...60) === diff
            sleep_remain = 60 - diff
            deposit_txid_state = 3
          else
            sleep_remain = 60
            deposit_txid_state = 4
          end

          sleep sleep_remain

          deposit_txid_data = get_data(payload)

          case deposit_txid_state
          when 1
            notify(deposit_txid_data, deposit_txid_state)
            Rails.cache.write "peatio:deposit:#{deposit_txid_data.txid_by_user}:#{deposit_txid_data.currency}:state", 2
          when 2
            notify(deposit_txid_data, deposit_txid_state)
            Rails.cache.write "peatio:deposit:#{deposit_txid_data.txid_by_user}: #{deposit_txid_data.currency}:state", 3
          when 3
            notify(deposit_txid_data, deposit_txid_state)
            Rails.cache.write "peatio:deposit:#{deposit_txid_data.txid_by_user}: #{deposit_txid_data.currency}:state", 4
          else
            notify(deposit_txid_data, deposit_txid_state)
          end
        end
        Rails.cache.delete("peatio:deposit:#{deposit_txid_data.txid_by_user}:#{deposit_txid_data.currency}:data")
        Rails.cache.delete("peatio:deposit:#{deposit_txid_data.txid_by_user}:#{deposit_txid_data.currency}:state")
        Thread.exit
      end
    end

    def get_data(deposit)
      Rails.cache.read("peatio:deposit:#{deposit[:txid_by_user]}:#{deposit[:currency]}:data")
    end

    def get_state(deposit)
      Rails.cache.read("peatio:deposit:#{deposit[:txid_by_user]}:#{deposit[:currency]}:state")
    end

    def check_state(aasm_state)
      unless aasm_state == 'accepted' or aasm_state == 'cancelled' or aasm_state == 'rejected' or aasm_state == 'warning'
        true
      else
        false
      end
    end

    def notify(deposit, level)
      puts "Notificacao Deposit TXID #{deposit.txid_by_user} := STATE HORAS #{level}"
    end

      add_transaction_tracer :process, :category => :task
      add_transaction_tracer :create_thread_and_notify, :category => :task
      add_transaction_tracer :get_data, :category => :task
      add_transaction_tracer :get_state, :category => :task
      add_transaction_tracer :check_state, :category => :task
      add_transaction_tracer :notify, :category => :task

  end
end
