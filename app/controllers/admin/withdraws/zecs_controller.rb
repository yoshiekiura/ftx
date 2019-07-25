module Admin
  module Withdraws
    class ZecsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Zec'

      def index
        @one_zecs = @zecs.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_zecs = @zecs.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @zec.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @zec.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
