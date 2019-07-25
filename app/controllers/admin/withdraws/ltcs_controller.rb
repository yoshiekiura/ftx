module Admin
  module Withdraws
    class LtcsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Ltc'

      def index
        @one_ltcs = @ltcs.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_ltcs = @ltcs.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @ltc.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @ltc.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
