module Private
  module Deposits
    class XrpsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end

