module Admin
  module Withdraws
    class RifsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Rif'

      def index
        @one_rifs = @rifs.with_aasm_state(:accepted).order("id DESC")
                        .page(params[:page])
        @all_rifs = @rifs.without_aasm_state(:accepted, :processing)
                        .order("id DESC")
                        .page(params[:page])
      end

      def show
      end

      def update
        @rif.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @rif.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
