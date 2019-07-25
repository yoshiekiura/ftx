
module Private
  module Deposits
    class DepositTxidsController < ApplicationController

      def create
         @deposit = current_user.deposits.where(txid_by_user: params[:txid])

         @currency = Currency.where(code: params[:currency])

         @account = Account.where(member_id: current_user.id, currency: @currency[0].id)

         if  params[:amount].nil?
          @amount_ret =  0.0000000000000001
         else
          @amount_ret =  params[:amount]
         end
         if  params[:fee].nil?
           @fee_ret =  0.0000000000000000
         else
           @fee_ret =  params[:fee]
         end
         #type:   'Deposits::'+@currency[0].code.to_s.capitalize
         if @deposit.blank?
             @deposit = Deposit.new(
                 txid_by_user: params[:txid],
                 account_id:   @account[0].id,
                 member_id:    current_user.id,
                 amount:       @amount_ret,
                 fee:         @fee_ret,
                 currency:     @currency[0].id,
                 aasm_state:   'submitting',
                 type:   'Deposits::DepositTxid'

             )
           ActiveRecord::Base.transaction do
=begin
             if @deposit.save
               render json: @deposit
             else
               render text: @deposit.errors.full_messages.join, status: 403
             end
=end

             if @deposit.save
               return render :json => {'msg': I18n.t('js.funds.deposit_coin.msg1'), 'status': 200}
             else
               return render :json => {'msg': I18n.t('js.funds.deposit_coin.msg2'), 'status': 400}
             end

           end
         end


      end
    end
  end
end
