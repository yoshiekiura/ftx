module Private
  module Withdraws
    class XarsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
