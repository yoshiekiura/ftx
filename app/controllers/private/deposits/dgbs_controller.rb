module Private
  module Deposits
    class DgbsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

