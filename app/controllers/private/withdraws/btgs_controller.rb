module Private
  module Withdraws
    class BtgsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
