module Admin
  module Deposits
    class BtgsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Btg'

      def index
        @btgs = @btgs.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @btgs.accept! if @btgs.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
