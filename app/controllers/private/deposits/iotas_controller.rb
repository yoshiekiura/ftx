module Private
  module Deposits
    class IotasController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

