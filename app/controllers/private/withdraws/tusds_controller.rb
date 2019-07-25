module Private
  module Withdraws
    class TusdsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
