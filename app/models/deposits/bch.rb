module Deposits
  class Bch < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
