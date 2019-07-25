module Admin
  module Deposits
    class BtcsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Btc'

      def index
        @btcs = @btcs.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @btcs.accept! if @btcs.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
