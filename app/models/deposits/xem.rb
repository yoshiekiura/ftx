module Deposits
  class Xem < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
