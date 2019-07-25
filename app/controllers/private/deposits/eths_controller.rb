module Private
  module Deposits
    class EthsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

