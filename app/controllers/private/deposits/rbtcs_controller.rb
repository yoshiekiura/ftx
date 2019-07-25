module Private
  module Deposits
    class RbtcsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

