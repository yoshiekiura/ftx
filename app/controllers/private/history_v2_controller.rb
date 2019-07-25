require 'csv'
module Private
  class Historyv2Controller < BaseController

    helper_method :tabs

    def account
      @market = current_market

      @deposits = Deposit.where(member: current_user).with_aasm_state(:accepted)
      @withdraws = Withdraw.where(member: current_user).with_aasm_state(:done)

      @transactions = (@deposits + @withdraws).sort_by {|t| -t.created_at.to_i}
      @transactions = Kaminari.paginate_array(@transactions).page(params[:page]).per(20)
    end

    def trades
      trades = current_user.trades

      unless params[:select_side].blank?
        @select_side = params[:select_side]
        member_shift = {'sell' => 'ask_member_id',
                        'buy' => 'bid_member_id'}
        field = member_shift[params[:select_side].to_s]
        trades = trades.where("#{field} = ?", current_user.id)
      else
        trades = current_user.trades.includes(:ask_member).includes(:bid_member)
      end

      unless params[:select_market].blank?
        @select_market = params[:select_market]
        trades = trades.where('currency = ?', params[:select_market])
      end

      unless params[:start].blank? && params[:end].blank?
        @start = params[:start]
        @end = params[:end]
        trades = trades.where('created_at BETWEEN ? AND ?', params[:start]+' 00:00:00', params[:end]+' 23:59:59')
      end

      unless params[:select_date].blank?
        @selected_date = params[:select_date]
        case params[:select_date]
        when 'today'
          trades = trades.where('created_at >= ?', Date.today)
        when 'yesterday'
          trades = trades.where('created_at >= ?', Date.yesterday)
        when 'one_week'
          trades = trades.where('created_at >= ?', 1.week.ago)
        when 'one_month'
          trades = trades.where('created_at >= ?', 1.month.ago)
        end
      end

      trades = trades.order('id desc').page(params[:page]).per(params[:select_per_page])
      @select_per_page = params[:select_per_page]

      @trades = trades

    end

    def orders
      orders = current_user.orders
      unless params[:select_side].blank?
        @select_side = params[:select_side]
        orders = orders.where("type = ?", "Order" + params[:select_side].camelcase)
      end

      unless params[:select_market].blank?
        @select_market = params[:select_market]
        orders = orders.where('currency = ?', params[:select_market])
      end

      unless params[:start].blank? && params[:end].blank?
        @start = params[:start]
        @end = params[:end]
        orders = orders.where('created_at BETWEEN ? AND ?', params[:start]+' 00:00:00', params[:end]+' 23:59:59')
      end


      unless params[:select_date].blank?
        @selected_date = params[:select_date]
        case params[:select_date]

        when 'today'
          orders = orders.where('created_at >= ?', Date.today)
        when 'yesterday'
          orders = orders.where('created_at >= ?', Date.yesterday)
        when 'one_week'
          orders = orders.where('created_at >= ?', 1.week.ago)
        when 'one_month'
          orders = orders.where('created_at >= ?', 1.month.ago)
        end
      end

      orders = orders.order('id desc').page(params[:page]).per(params[:select_per_page])
      @select_per_page = params[:select_per_page]

      @orders = orders
    end

    def payments
      @payments = current_user.trades
                      .includes(:ask_member).includes(:bid_member)
                      .order('id desc').page(params[:page]).per(20)
    end

    private

    def tabs
      {order: ['header.my_order_history', order_history_v2_path],
       trade: ['header.my_trade_history', trade_history_v2_path],
       payment: ['header.payment_history', payment_history_v2_path]
      }
    end

  end
end
