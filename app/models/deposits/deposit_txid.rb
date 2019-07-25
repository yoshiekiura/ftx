module Deposits
  class DepositTxid < ::Deposit
    after_create :enqueue_state

    def enqueue_state

      payload = self.as_json
      Rails.cache.write "peatio:deposit:#{self.txid_by_user}:#{self.currency}:data", self
      Rails.cache.write "peatio:deposit:#{self.txid_by_user}:#{self.currency}:state", 1
      AMQPQueue.enqueue(:deposit_txid, payload, {persistent: true})

    end

  end
end
