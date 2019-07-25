require 'rubygems'
require 'stratum'

Stratum.user = 'your_user'
Stratum.secret = 'your_secret'
Stratum.host = 'host'

Stratum.logger.level = Logger::DEBUG
response = Stratum::Wallet.list({ currency: :btc })

puts response.status
puts response.success?
puts response.data