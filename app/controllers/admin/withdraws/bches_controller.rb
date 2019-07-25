module Admin
  module Withdraws
    class BchesController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Bch'

      def index
        @one_bches = @bches.with_aasm_state(:accepted)
                         .order("id DESC")
                         .page(params[:page])
        @all_bches = @bches.without_aasm_state(:accepted, :processing)
                         .order("id DESC")
                         .page(params[:page])
      end

      def show
      end

      def update
        @bch.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @bch.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
