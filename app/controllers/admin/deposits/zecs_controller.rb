module Admin
  module Deposits
    class ZecsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Zec'

      def index
        @zecs = @zecs.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end
      
      def update
        @zecs.accept! if @zecs.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
