module Admin
  module Withdraws
    class SatoshisController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Satoshi'

      def index
        @one_satoshis = @satoshis.with_aasm_state(:accepted).order("id DESC")
                            .page(params[:page])
        @all_satoshis = @satoshis.without_aasm_state(:accepted, :processing)
                            .order("id DESC")
                            .page(params[:page])
      end

      def show
      end

      def update
        @satoshi.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @satoshi.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
