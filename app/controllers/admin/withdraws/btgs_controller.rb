module Admin
  module Withdraws
    class BtgsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Btg'

      def index
        @one_btgs = @btgs.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_btgs = @btgs.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @btg.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @btg.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
