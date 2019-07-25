module Deposits
  class Xrp < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
