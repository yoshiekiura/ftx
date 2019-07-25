module Admin
  module Deposits
    class LtcsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Ltc'

      def index
        @ltcs = @ltcs.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @ltcs.accept! if @ltcs.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
