module Admin
  module Withdraws
    class XrpsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Xrp'

      def index
        @one_xrps = @xrps.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_xrps = @xrps.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @xrp.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @xrp.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
