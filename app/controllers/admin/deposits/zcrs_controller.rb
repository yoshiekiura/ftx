module Admin
  module Deposits
    class ZcrsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Zcr'

      def index
        @zcrs = @zcrs.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end
      
      def update
        @zcrs.accept! if @zcrs.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
