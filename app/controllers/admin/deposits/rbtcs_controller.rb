module Admin
  module Deposits
    class RbtcsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Rbtc'

      def index
        @rbtcs = @rbtcs.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @rbtcs.accept! if @rbtcs.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
