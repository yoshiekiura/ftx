module Deposits
  class Smart < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
