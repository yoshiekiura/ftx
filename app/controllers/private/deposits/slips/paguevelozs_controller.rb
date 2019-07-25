module Private
  module Deposits
    module Slips
      class PaguevelozsController < ::Private::Deposits::Slips::BaseController
        include ::Deposits::CtrlSlipable


        def create
          @deposit = model_kls.new(deposit_params)

          if @deposit.save
            render json: @deposit
          else
            render text: @deposit.errors.full_messages.join, status: 403
          end
        end

        private


      end
    end
  end
end

