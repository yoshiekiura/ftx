module Deposits
  module CtrlSlipable
    extend ActiveSupport::Concern

    included do
      before_filter :fetch
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

      params[:deposit][:fund_source_id] = 0
      params.require(:deposit).permit(:fund_source_id, :slip, :amount, :currency, :account_id, :member_id)
    end
  end
end
