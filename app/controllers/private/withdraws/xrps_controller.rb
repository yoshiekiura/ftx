module Private
  module Withdraws
    class XrpsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
