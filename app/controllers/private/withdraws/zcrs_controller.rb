module Private
  module Withdraws
    class ZcrsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
