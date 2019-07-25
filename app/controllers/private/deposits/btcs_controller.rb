module Private
  module Deposits
    class BtcsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

