module Private
  module Withdraws
    class ZecsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
