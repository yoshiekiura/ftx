module Private
  module Deposits
    class XemsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

