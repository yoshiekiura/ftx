module Private
  module Withdraws
    class SmartsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
