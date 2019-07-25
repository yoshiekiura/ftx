namespace :order do
  task cancel_active: :environment do
    Order.active.each do |order|
      puts "Order to cancel #{order.id} | state = #{order.state}"

      ordering = Ordering.new(order)
      ordering.cancel!

      order.reload

      puts "Order cancelled #{order.id} | state = #{order.state}"
    end
  end 

  task mock: :environment do
    m = Member.find_by_email 'foo@peatio.dev'
    market = Market.find 'btcbrl'

    low = 2150
    high = 2250
    mid = 2200
    (low..high).each do |price|
      puts "price = #{price.inspect}"
      klass = price < mid ?  OrderBid : OrderAsk
      volume = rand

      order = klass.new(
        source:        'APIv2',
        state:         ::Order::WAIT,
        member_id:     m.id,
        ask:           market.base_unit,
        bid:           market.quote_unit,
        currency:      market.id,
        ord_type:      'limit',
        price:         BigDecimal(Random.new.rand.to_s).round(3) + price,
        volume:        volume,
        origin_volume: volume
      )

      Ordering.new(order).submit
    end
  end
end
