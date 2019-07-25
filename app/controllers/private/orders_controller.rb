module Private
  class OrdersController < BaseController

    def destroy
      ActiveRecord::Base.transaction do
        order = current_user.orders.find(params[:id])
        @market = Market.find_by_id(order.ask+order.bid)
        ordering = Ordering.new(order, @market)
        if ordering.cancel
          render status: 200, nothing: true
        else
          render status: 500, nothing: true
        end
      end
    end

    def clear
      @market = current_market
      @orders = current_user.orders.with_currency(current_market).with_state(:wait)
      Ordering.new(@orders,@market).cancel
      render status: 200, nothing: true
    end

    def update
      @market = current_market
      ActiveRecord::Base.transaction do
        order = current_user.orders.find(params[:id])
        order.price = params[:price]
        order.volume = params[:amount]
        ordering = Ordering.new(order,@market)

        if ordering.submit
          render status: 200, nothing: true
        else
          render status: 500, nothing: true
        end
      end

    end

    def show
      ActiveRecord::Base.transaction do
        order = current_user.orders.find(params[:id])
        render status: 200, json: order.as_json
      end

    end

  end
end
