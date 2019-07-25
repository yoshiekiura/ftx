module Admin
  module Withdraws
    class RbtcsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Rbtc'

      def index
        @one_rbtcs = @rbtcs.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_rbtcs = @rbtcs.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @rbtc.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @rbtc.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
