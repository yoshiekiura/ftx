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
logger.info "Samurai deposit start loop"

while($running) do
  Deposit.where(type:'Deposits::Bank').with_aasm_state(:submitting, :submitted).each do |dp|
    begin
      unless dp.fund_uid == 'BankSlip/Boleto'
        worker = Worker::SamuraiDeposit.new(dp)
        worker.process
      end

    rescue
      SystemMailer.samurai_status_error(dp, $!.message, $!.backtrace.join("\n"))
      logger.error "Error on Deposit: #{$!}"
      logger.error $!.backtrace.join("\n")
      next
    end
  end

  sleep 60
end
