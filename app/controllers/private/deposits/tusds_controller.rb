module Private
  module Deposits
    class TusdsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

