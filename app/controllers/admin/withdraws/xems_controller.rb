module Admin
  module Withdraws
    class XemsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Xem'

      def index
        @one_xems = @xems.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_xems = @xems.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @xem.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @xem.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
