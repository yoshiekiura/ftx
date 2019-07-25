#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"
#Rails.logger = logger = Logger.new STDOUT
require 'logger'
logger = Logger.new STDOUT

# Emulate loading workers from command line
# no daemons applied
# ex: ruby lib/daemons/amqp_daemon.rb EMULE queue=peatio:amqp:notification workers=sms_notification,email_notification
if ARGV.include? 'EMULE'
  logger.debug "Emulating workers over AMQP channel"

  argv_reset = []
  ARGV.each do |argument|
    if argument.include? 'queue'
      $0 = argument.split('=')[1]
    end
    if argument.include? 'workers'
      argv_reset = argument.split('=')[1].split(',')
    end

  end
  ARGV = argv_reset
end

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

raise "bindings must be provided." if ARGV.size == 0

logger.debug "$0 = #{$0}"
logger.debug "ARGV = #{ARGV.inspect}"

conn = Bunny.new AMQPConfig.connect,:automatic_recovery => true
conn.start

ch = conn.create_channel
id = $0.split(':')[2]
prefetch = AMQPConfig.channel(id)[:prefetch] || 0
ch.prefetch(prefetch) if prefetch > 0

terminate = proc do
  # logger is forbidden in signal handling, just use puts here
  logger.info "Terminating threads .."
  ch.work_pool.kill
  logger.debug "Stopped."
end

Signal.trap("INT",  &terminate)
Signal.trap("TERM", &terminate)

workers = []
ARGV.each do |id|
  worker = AMQPConfig.binding_worker(id)
  queue  = ch.queue *AMQPConfig.binding_queue(id)

  if args = AMQPConfig.binding_exchange(id)
    x = ch.send *args

    case args.first
    when 'direct'
      queue.bind x, routing_key: AMQPConfig.routing_key(id)
    when 'topic'
      AMQPConfig.topics(id).each do |topic|
        queue.bind x, routing_key: topic
      end
    else
      queue.bind x
    end
  end

  clean_start = AMQPConfig.data[:binding][id][:clean_start]
  queue.purge if clean_start

  manual_ack  = AMQPConfig.data[:binding][id][:manual_ack]
  queue.subscribe(manual_ack: manual_ack) do |delivery_info, metadata, payload|
    begin
      worker.process JSON.parse(payload), metadata, delivery_info
    rescue Exception => e
      logger.fatal e
      logger.fatal e.backtrace.join("\n")
    ensure
      ch.ack(delivery_info.delivery_tag) if manual_ack
    end
  end
  workers << worker
end

%w(USR1 USR2).each do |signal|
  Signal.trap(signal) do
    logger.debug "#{signal} received."
    handler = "on_#{signal.downcase}"
    workers.each {|w| w.send handler if w.respond_to?(handler) }
  end
end

ch.work_pool.join
logger.debug "End. Listening"
