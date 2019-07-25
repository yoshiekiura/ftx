module Private
  module Deposits
    class BchesController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

