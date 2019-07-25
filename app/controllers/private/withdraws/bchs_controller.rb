module Private
  module Withdraws
    class BchsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
