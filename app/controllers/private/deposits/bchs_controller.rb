module Private
  module Deposits
    class BchsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

