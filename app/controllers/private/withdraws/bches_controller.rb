module Private
  module Withdraws
    class BchesController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
