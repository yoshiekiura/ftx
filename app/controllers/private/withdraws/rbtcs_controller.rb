module Private
  module Withdraws
    class RbtcsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
