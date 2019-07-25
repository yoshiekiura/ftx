module Deposits
  class Tusd < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable
  end
end
