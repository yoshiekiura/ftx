module Private
  module Withdraws
    class RifsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
