module Admin
  module Deposits
    class EthsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Eth'

      def index
        @eths = @eths.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @eths.accept! if @eths.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
