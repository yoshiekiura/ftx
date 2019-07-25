module Deposits
  class Xar < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
