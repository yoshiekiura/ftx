module Admin
  module Deposits
    class TusdsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Tusd'

      def index
        @tusds = @tusds.includes(:member).
          order('id DESC').page(params[:page])
      end

      def show
      end
      
      def update
        @tusds.accept! if @tusds.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
