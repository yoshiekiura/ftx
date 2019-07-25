module Deposits
  module CtrlBankable
    extend ActiveSupport::Concern

    included do
      before_filter :fetch
    end

    def create
      @deposit = model_kls.new(deposit_params)

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

      cpf, type, samurai_code = @deposit.samurai_details

      expire = Time.now.change({ hour: 20, min: 0, sec: 0 }).to_datetime + 2.days
      begin
        DepositMailer.created(@deposit.id, samurai_code, expire, type, @deposit.amount)
      rescue
        puts "Fail send mail"
      end

      render nothing: true
    end

    private

    def fetch
      @account = current_user.get_account(channel.currency)
      @model = model_kls
      @fund_sources = current_user.fund_sources.with_currency(channel.currency)
      @assets = model_kls.where(member: current_user).order(:id).reverse_order.limit(10)
    end

    def deposit_params
      params[:deposit][:currency] = channel.currency
      params[:deposit][:member_id] = current_user.id
      params[:deposit][:account_id] = @account.id
      params[:deposit][:amount] = "#{params[:deposit][:amount]}.08".gsub('R$','')


      unless params[:deposit][:fund_source].blank?
      params[:deposit][:fund_source_id] = params[:deposit][:fund_source]
      else
        params[:deposit][:fund_source_id] = -1
      end

      params.require(:deposit).permit(:fund_source_id, :amount, :currency, :account_id, :member_id)
    end
  end
end
