module Private
  module Deposits
    class XarsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

