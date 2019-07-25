module Deposits
  class Rif < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
