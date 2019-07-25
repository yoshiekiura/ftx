module Private
  module Withdraws
    class IotasController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
