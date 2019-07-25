module Private
  class FundsController < BaseController

    layout 'fundsV2'

    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!

    def index
      @deposit_channels = DepositChannel.all
      @withdraw_channels = WithdrawChannel.all
      @currencies = Currency.all.sort
      @deposits = current_user.deposits.where('created_at BETWEEN ? AND ?', 3.months.ago, Time.now)
      @accounts = current_user.accounts
      @withdraws = current_user.withdraws.where('created_at BETWEEN ? AND ?', 3.months.ago, Time.now)
      @fund_sources = current_user.fund_sources
      @banks = Bank.all

      gon.jbuilder
    end

    def gen_address
      current_user.accounts.each do |account|
        next if not account.currency_obj.coin?

        if account.payment_addresses.blank?
          account.payment_addresses.create(currency: account.currency)
        else
          address = account.payment_addresses.last
          address.gen_address if address.address.blank?
        end
      end
      render nothing: true
    end

    end
end

