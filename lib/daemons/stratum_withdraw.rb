#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do
  $running = false
end

Rails.logger = logger = Logger.new STDOUT
logger.info "Stratum start loop WITHDRAW"

while($running) do

  Currency.all.each do |currency|
    if currency.coin
      worker = Worker::StratumWithdraw.new(currency)
      worker.process
    end
  end
  logger.info "-----------------"

  sleep 60
end
