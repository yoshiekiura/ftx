module Deposits
  module Slips
    class Pagpay < ::DepositSlip
      include ::AasmAbsolutely
      include ::Deposits::Slipable
      include ::FundSourceable

      def charge!(txid)
        with_lock do
          submit!
          accept!
          touch(:done_at)
          update_attribute(:txid, txid)
        end
      end

      def reject_it!(txid)
        with_lock do
          submit!
          reject!
          touch(:done_at)
          update_attribute(:txid, txid)
        end
      end

      private

    end
  end
end
