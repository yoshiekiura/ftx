json.asks @asks
json.bids @bids
json.trades @trades

if @member

  json_my_orders = json.my_orders *([@orders_wait] + Order::ATTRIBUTES)
  json_my_orders.each do | order |
    order['market'] = order['ask'] + order['bid']
  end

  json.my_trades @trades_done.map(&:for_notify)
  json_my_orders


end
