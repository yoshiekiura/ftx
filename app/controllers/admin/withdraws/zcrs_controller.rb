module Admin
  module Withdraws
    class ZcrsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Zcr'

      def index
        @one_zcrs = @zcrs.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_zcrs = @zcrs.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @zcr.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @zcr.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
