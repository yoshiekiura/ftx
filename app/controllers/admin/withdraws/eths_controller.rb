module Admin
  module Withdraws
    class EthsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Eth'

      def index
        @one_eths = @eths.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_eths = @eths.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @eth.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @eth.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
