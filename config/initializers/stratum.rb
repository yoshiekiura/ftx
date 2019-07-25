Stratum.user   = ENV['STRATUM_USER']
Stratum.secret = ENV['STRATUM_SECRET']
Stratum.host   = ENV['STRATUM_HOST']
Stratum.dev    = ENV['STRATUM_DEV']

Stratum.logger = Logger.new( "#{Rails.root}/log/stratum.log")
Stratum.logger.level = Logger::DEBUG

unless ENV["RAILS_ENV"] == 'test'
  # Worker::StratumCurrency.new().process
end