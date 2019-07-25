module Deposits
  class Ltc < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
