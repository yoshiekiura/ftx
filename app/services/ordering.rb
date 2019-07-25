class Ordering

  class CancelOrderError < StandardError; end

  def initialize(order_or_orders, market = nil)
    @market = market
    @orders = Array(order_or_orders)
  end

  def submit
    ActiveRecord::Base.transaction do
      @orders.each {|order| do_submit order }
    end

    @orders.each do |order|
      order_matching_attributes = order.to_matching_attributes
      order_matching_attributes[:market] = @market.id
      AMQPQueue.enqueue(:matching, action: 'submit', order: order_matching_attributes)
    end
    
  end

  def cancel
    @orders.each {|order| do_cancel order }
  end

  def cancel!
    ActiveRecord::Base.transaction do
      @orders.each {|order| do_cancel! order }
    end
  end

  private

  def do_submit(order)
    order.fix_number_precision # number must be fixed before computing locked
    order.locked = order.origin_locked = order.compute_locked
    order.save!

    account = order.hold_account
    account.lock_funds(order.locked, reason: Account::ORDER_SUBMIT, ref: order)
  end

  def do_cancel(order)
    order_matching_attributes = order.to_matching_attributes
    order_matching_attributes[:market] = @market.id
    AMQPQueue.enqueue(:matching, action: 'cancel', order: order_matching_attributes)
  end

  def do_cancel!(order)
    account = order.hold_account
    order   = Order.find(order.id).lock!

    if order.state == Order::WAIT
      order.state = Order::CANCEL
      account.unlock_funds(order.locked, reason: Account::ORDER_CANCEL, ref: order)
      order.save!
    else
      raise CancelOrderError, "Only active order can be cancelled. id: #{order.id}, state: #{order.state}"
    end
  end
  # add_transaction_tracer :initialize,
  #                        :name => 'initialize',
  #                        :category => "Ordering/initialize"
  # add_transaction_tracer :submit,
  #                        :name => 'submit',
  #                        :category => "Ordering/submit"
  # add_transaction_tracer :cancel,
  #                        :name => 'cancel',
  #                        :category => "Ordering/cancel"
  # add_transaction_tracer :cancel!,
  #                        :name => 'cancel!',
  #                        :category => "Ordering/cancel!"
  # add_transaction_tracer :do_submit,
  #                        :name => 'do_submit',
  #                        :category => "Ordering/do_submit"
  # add_transaction_tracer :do_cancel,
  #                        :name => 'do_cancel',
  #                        :category => "Ordering/do_cancel"
  # add_transaction_tracer :do_cancel!,
  #                        :name => 'do_cancel!',
  #                        :category => "Ordering/do_cancel!"



end
