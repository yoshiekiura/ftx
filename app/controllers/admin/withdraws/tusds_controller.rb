module Admin
  module Withdraws
    class TusdsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Tusd'

      def index
        @one_tusds = @tusds.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_tusds = @tusds.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @tusd.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @tusd.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
