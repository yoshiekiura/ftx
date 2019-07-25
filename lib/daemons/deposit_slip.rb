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
logger.info "Start loop DEPOSIT slip"

while($running) do
  Deposit.where("type like'Deposits::Slips::%'").
      where("created_at > '#{Time.now.to_datetime - 7.days}'").
      with_aasm_state(:submitting, :submitted).each do |dp|

    begin
	 case dp.type
      when 'Deposits::Slips::Tronipay'
        puts 'Deposits::Slips::Tronipay KIND'
        worker = Worker::Deposits::Slips::Tronipay.new(dp)
        worker.process

      when 'Deposits::Slips::Pagpay'
        puts 'Deposits::Slips::Pagpay KIND'

      when 'Deposits::Slips::Pagueveloz'
        puts 'Deposits::Slips::Pagueveloz KIND'

      end
    rescue
      SystemMailer.deposit_slip_status_error(dp, $!.message, $!.backtrace.join("\n"))
      logger.error "Error on Deposit Slip: #{$!}"
      logger.error $!.backtrace.join("\n")
      next
    end
  end

  sleep 60
end
