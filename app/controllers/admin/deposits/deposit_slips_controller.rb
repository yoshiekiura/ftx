module Admin
  module Deposits
    class DepositSlipsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposit'

      def index

      end

      def show
        @deposit = Deposit.find(params[:id])
        flash.now[:notice] = t('admin.deposits.banks.show.notice') if @deposit.aasm_state.accepted?
      end

      def update
        @deposit = Deposit.find(params[:id])
        if target_params[:txid].blank?
          flash[:alert] = t('admin.deposits.banks.update.blank_txid')
          redirect_to :back and return
        end

        @deposit.charge!(target_params[:txid])

        redirect_to :back
      end

      private
      def target_params
        params.require(:deposit).permit(:sn, :holder, :amount, :created_at, :txid)
      end
    end
  end
end

