module Admin
  class DashboardController < BaseController
    skip_load_and_authorize_resource

    def index
      @daemon_statuses = Global.daemon_statuses
      @currencies_summary = Currency.all.map(&:summary)

      @register_count = Member.count
      @deposit_count = Deposit.count
      @withdraw_count = Withdraw.count
      @trade_count = Trade.count

      @system_slip_method = Slip.system_slip_method
      @slip_methods = Slip.enumerize
    end
  end
end
