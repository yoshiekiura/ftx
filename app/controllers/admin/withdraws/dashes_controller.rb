module Admin
  module Withdraws
    class DashesController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Dash'

      def index
        @one_dashes = @dashes.with_aasm_state(:accepted).order("id DESC")
                          .page(params[:page])
        @all_dashes = @dashes.without_aasm_state(:accepted, :processing)
                          .order("id DESC")
                          .page(params[:page])
      end

      def show
      end

      def update
        @dash.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @dash.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
