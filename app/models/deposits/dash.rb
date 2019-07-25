module Deposits
  class Dash < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
