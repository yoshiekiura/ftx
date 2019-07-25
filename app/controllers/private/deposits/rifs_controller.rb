module Private
  module Deposits
    class RifsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

