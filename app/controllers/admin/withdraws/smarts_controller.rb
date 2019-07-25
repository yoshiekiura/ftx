module Admin
  module Withdraws
    class SmartsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Smart'

      def index
        @one_smarts = @smarts.with_aasm_state(:accepted).order("id DESC")
                          .page(params[:page])
        @all_smarts = @smarts.without_aasm_state(:accepted, :processing)
                          .order("id DESC")
                          .page(params[:page])
      end

      def show
      end

      def update
        @smart.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @smart.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
