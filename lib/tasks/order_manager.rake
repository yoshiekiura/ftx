namespace :order_manager do
  desc "Cancel all Orders with state = :wait"
  task cancel_all_orders: :environment do

    worker = Worker::OrderProcessor.new
    orders = Order.where(state: 100)

    orders.each do |order|
      args = {}
      args['id'] = order.id
      args['volume'] = order.volume

      puts '==============='
      puts "Canceling Order: #{order.id}"
      puts "Volume Order: #{order.volume}"

      begin
        worker.check_and_cancel args
      rescue
        order.state = 0
        order.save
      end
    end

  end

  desc "Cancel all orders by user id with state = :wait"
  task cancel_all_orders_by_member_id: :environment do

    if ENV['MEMBER_ID'].blank?
      puts "Please inform the param MEMBER_ID"
      exit 0
    else
      worker = Worker::OrderProcessor.new
      orders = Order.where(member_id: ENV['MEMBER_ID']).where(state: 100)

      orders.each do |order|
        args = {}
        args['id'] = order.id
        args['volume'] = order.volume

        puts '==============='
        puts "Canceling Order: #{order.id}"
        puts "Volume Order: #{order.volume}"

        begin
          worker.check_and_cancel args
        rescue
          order.state = 0
          order.save
        end

      end


    end

  end

end
