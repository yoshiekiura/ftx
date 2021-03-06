module Worker
  require 'newrelic_rpm'
  class WalletStats < Stats
     include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def initialize(currency)
      super()
      @currency = currency
    end

    def run
      [60, 1440, 10080].each do |period|
        collect period
      end
      Rails.logger.info "#{self.to_s} collected."
    end

    def to_s
      "#{self.class.name} (#{@currency.code})"
    end

    def key_for(period)
      "peatio:stats:wallet:#{@currency.code}:#{period}"
    end

    def point_n(from, period)
      if (from+period.minutes) < (Time.now-period.minutes)
        [from.to_i, 0, 0, 0]
      else
        balance = Account.balance_sum(@currency.code)
        locked  = Account.locked_sum(@currency.code)
        [from.to_i, balance.to_f, locked.to_f, (balance+locked).to_f]
      end
    end
     add_transaction_tracer :run, :category => :task
     add_transaction_tracer :key_for, :category => :task
     add_transaction_tracer :point_n, :category => :task
  end
end
