module Private
  module Withdraws
    class XemsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
