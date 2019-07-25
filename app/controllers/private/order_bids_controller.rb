module Private
  class OrderBidsController < BaseController
    include Concerns::OrderCreation

    def show
      @last_bid = OrderBid.get_last
    end

    def create
      @market = current_market
      @order = OrderBid.new(order_params(:order_bid))
      order_submit
    end

    def clear
      @market = current_market
      @orders = OrderBid.where(member_id: current_user.id).with_state(:wait).with_currency(current_market)
      Ordering.new(@orders,@market).cancel
      render status: 200, nothing: true
    end

  end
end
