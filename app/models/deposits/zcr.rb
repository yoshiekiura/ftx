module Deposits
  class Zcr < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
