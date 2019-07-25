module Private
  module Deposits
    class ZcrsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

