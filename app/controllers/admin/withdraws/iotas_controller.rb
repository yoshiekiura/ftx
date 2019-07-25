module Admin
  module Withdraws
    class IotasController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Iota'

      def index
        @one_iotas = @iotas.with_aasm_state(:accepted).order("id DESC")
                         .page(params[:page])
        @all_iotas = @iotas.without_aasm_state(:accepted, :processing)
                         .order("id DESC")
                         .page(params[:page])
      end

      def show
      end

      def update
        @iota.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @iota.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
