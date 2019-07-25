module Deposits
  class Iota < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
