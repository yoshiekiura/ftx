module Admin
  module Deposits
    class BchesController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Bch'

      def index
        @bches = @bches.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @bches.accept! if @bches.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
