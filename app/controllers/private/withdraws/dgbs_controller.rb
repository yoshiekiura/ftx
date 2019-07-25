module Private
  module Withdraws
    class DgbsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
