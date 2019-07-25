module Admin
  module Withdraws
    class XarsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Xar'

      def index
        @one_xars = @xars.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_xars = @xars.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @xar.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @xar.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
