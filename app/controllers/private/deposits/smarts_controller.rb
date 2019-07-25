module Private
  module Deposits
    class SmartsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

