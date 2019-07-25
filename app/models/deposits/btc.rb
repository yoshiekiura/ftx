module Deposits
  class Btc < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
