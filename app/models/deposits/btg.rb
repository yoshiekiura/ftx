module Deposits
  class Btg < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
