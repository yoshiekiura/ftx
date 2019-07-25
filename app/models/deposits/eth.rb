module Deposits
  class Eth < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
