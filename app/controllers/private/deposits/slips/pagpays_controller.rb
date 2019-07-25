module Private
  module Deposits
    module Slips
      class PagpaysController < ::Private::Deposits::Slips::BaseController
        include ::Deposits::CtrlSlipable
      end
    end
  end
end

