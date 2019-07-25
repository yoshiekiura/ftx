module Admin
  module Deposits
    class SmartsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Smart'

      def index
        @smarts = @smarts.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @smarts.accept! if @smarts.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
