module Admin
  module Withdraws
    class BtcsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Btc'

      def index
        @one_btcs = @btcs.with_aasm_state(:accepted)
                        .order("id DESC")
                        .page(params[:page])
        @all_btcs = @btcs.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @btc.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @btc.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
