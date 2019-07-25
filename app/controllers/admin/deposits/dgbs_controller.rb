module Admin
  module Deposits
    class DgbsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Dgb'

      def index
        @dgbs = @dgbs.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @dgbs.accept! if @dgbs.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
