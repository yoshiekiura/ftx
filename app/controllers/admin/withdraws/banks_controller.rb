module Admin
  module Withdraws
    class BanksController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Bank'

      def index
        @one_banks = @banks.with_aasm_state(:accepted, :processing)
                         .order("id DESC")
                         .page(params[:page])
        @all_banks = @banks.without_aasm_state(:accepted, :processing)
                         .order("id DESC")
                         .page(params[:page])
      end

      def show
      end

      def update
        if @bank.may_process?
          @bank.process!
        elsif @bank.may_succeed?
          @bank.succeed!
        end

        redirect_to :back, notice: t('private.withdraws.banks.update.notice')
      end

      def destroy
        @bank.reject!
        redirect_to :back, notice: t('private.withdraws.banks.destroy.notice')
      end
    end
  end
end
