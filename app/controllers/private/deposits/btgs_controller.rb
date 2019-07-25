module Private
  module Deposits
    class BtgsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

