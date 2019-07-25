module Admin
  module Deposits
    class BanksController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Bank'

      def index
        @one_banks = Deposit.all.where('currency = ?',1).with_aasm_state(:submitting, :warning, :submitted)
                         .order("id DESC")
                         .page(params[:page])
        @all_banks = Deposit.all.where('currency = ?',1).without_aasm_state(:submitting, :warning, :submitted)
                         .order("id DESC")
                         .page(params[:page])
      end

      def show
        flash.now[:notice] = t('.notice') if @bank.aasm_state.accepted?
      end

      def update
        if target_params[:txid].blank?
          flash[:alert] = t('.blank_txid')
          redirect_to :back and return
        end

        @bank.charge!(target_params[:txid])

        redirect_to :back
      end

      def update_txid_by_user
        if target_params[:txid_by_user].blank?
          flash[:alert] = t('.blank_txid')
          redirect_to :back and return
        end

        @bank.charge!(target_params[:txid_by_user])

        redirect_to :back
      end

      private
      def target_params
        params.require(:deposits_bank).permit(:sn, :holder, :amount, :created_at, :txid )
      end
    end
  end
end