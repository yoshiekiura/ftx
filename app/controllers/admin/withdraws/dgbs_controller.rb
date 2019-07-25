module Admin
  module Withdraws
    class DgbsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Dgb'

      def index
        @one_dgbs = @dgbs.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_dgbs = @dgbs.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @dgb.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @dgb.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
