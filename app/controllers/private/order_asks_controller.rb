module Private
  class OrderAsksController < BaseController
    include Concerns::OrderCreation

    def create
      @market = current_market
      @order = OrderAsk.new(order_params(:order_ask))
      order_submit
    end

    def clear
      @market = current_market
      @orders = OrderAsk.where(member_id: current_user.id).with_state(:wait).with_currency(current_market)
      Ordering.new(@orders,@market).cancel
      render status: 200, nothing: true
    end

  end
end
