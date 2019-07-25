
Samurai.host   = ENV['SAMURAI_HOST']

Samurai.logger = Logger.new( "#{Rails.root}/log/samurai.log")
Samurai.logger.level = Logger::DEBUG