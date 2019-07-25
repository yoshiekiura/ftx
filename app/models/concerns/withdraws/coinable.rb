module Withdraws
  module Coinable
    extend ActiveSupport::Concern

    def set_fee
      withdraw_fee = Currency.find_by_code(self.currency).withdraw_fee
      
      # Set free
      self.fee = withdraw_fee
    end

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def txout_info
      StratumEvent.find_by_operation_id(txout)
    end

    def audit!
      super
    end

    def as_json(options={})
      super(options).merge({
        blockchain_url: blockchain_url
      })
    end

  end
end

