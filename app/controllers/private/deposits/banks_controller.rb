module Private
  module Deposits
    class BanksController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlBankable

      def create
        @deposit = model_kls.new(deposit_params)
        unless params[:deposit][:type].nil?
          @deposit.txid = params[:deposit][:type]
        else
          fund = FundSource.find(params[:deposit][:fund_source_id])
          unless fund.extra != "_341"
            type = "TEF"
          else
            type = "TED"
          end

          @deposit.txid = type
        end

        if @deposit.save
          render json: @deposit
        else
          render text: @deposit.errors.full_messages.join, status: 403
        end
      end

      def destroy
        @deposit = current_user.deposits.find(params[:id])
        @deposit.cancel!
        render nothing: true
      end

      def update
        @deposit = current_user.deposits.find(params[:id])
        @deposit.submit!

        cpf = @deposit.txid.split(':')[1]
        type = @deposit.txid.split(':')[0]
        samurai_code = type == "TED" ? cpf : @deposit.txid.split(':')[2]
        expire = Time.now.to_datetime + 2.days

        begin
          DepositMailer.created(@deposit.id, samurai_code, expire, type, @deposit.amount)

        rescue Exception => exception
          return false, exception.message

        end


        render nothing: true
      end
      # add_method_tracer :create
      # add_method_tracer :destroy
      # add_method_tracer :update

    end
  end
end
