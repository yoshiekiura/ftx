module Deposits
  class Rbtc < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
