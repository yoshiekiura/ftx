module Admin
  module Deposits
    class XrpsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Xrp'

      def index
        @xrps = @xrps.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @xrps.accept! if @xrps.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
