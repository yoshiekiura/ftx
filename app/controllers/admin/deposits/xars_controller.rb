module Admin
  module Deposits
    class XarsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Xar'

      def index
        @xars = @xars.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @xars.accept! if @xars.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
