module Private
  module Withdraws
    class EthsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
