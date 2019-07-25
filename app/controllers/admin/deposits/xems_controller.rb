module Admin
  module Deposits
    class XemsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Xem'

      def index
        @xems = @xems.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @xems.accept! if @xems.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
