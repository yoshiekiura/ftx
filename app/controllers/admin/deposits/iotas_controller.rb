module Admin
  module Deposits
    class IotasController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Iota'

      def index
        @iotas = @iotas.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @iotas.accept! if @iotas.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
