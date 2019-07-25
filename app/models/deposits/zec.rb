module Deposits
  class Zec < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
