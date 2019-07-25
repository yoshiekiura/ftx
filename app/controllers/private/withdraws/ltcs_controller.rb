module Private
  module Withdraws
    class LtcsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
