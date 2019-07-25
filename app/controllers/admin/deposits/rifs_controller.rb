module Admin
  module Deposits
    class RifsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Rif'

      def index
        @rifs = @rifs.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end

      def update
        @rifs.accept! if @rifs.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
