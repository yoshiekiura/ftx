module Private
  module Deposits
    class ZecsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

