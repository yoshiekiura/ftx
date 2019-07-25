module Private
  module Deposits
    class LtcsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

