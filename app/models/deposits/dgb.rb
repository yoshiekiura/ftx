module Deposits
  class Dgb < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
