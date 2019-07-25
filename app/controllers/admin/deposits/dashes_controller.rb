module Admin
  module Deposits
    class DashesController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Dash'

      def index
        @dashes = @dashes.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @dashes.accept! if @dashes.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
