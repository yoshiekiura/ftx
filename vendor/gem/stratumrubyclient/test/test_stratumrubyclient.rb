require 'stratumrubyclient'
require 'json'

@stratumrubyclient = StratumRubyClient.new(
  'API_USER_FROM_MOBILEAPP_QR',
  'API_SECRET_FROM_MOBILEAPP_QR',
  'https://coinbr.io/api')

def handle_api(apicall, payload)
  json_reply = false
  if payload != 0
    json_reply = @stratumrubyclient.send_api(apicall, payload)
  else 
    json_reply = @stratumrubyclient.send_api(apicall, 0)
  end
  if json_reply == false
    "Error in send_api, ending."
  else
    json_decoded = JSON.parse(json_reply)
  end
end

puts "--> API reply:"
JSON.pretty_generate(handle_api('getUser', 0))
puts "--> API reply:"
JSON.pretty_generate(handle_api('getWallets', 0))
puts "--> API reply:"
JSON.pretty_generate(handle_api('getTransactions', 0))
puts "--> API reply:"
puts JSON.pretty_generate(
  handle_api('getWalletAddress', {:wallet_id => '312728'}))
# Failure test
puts "--> API reply:"
puts JSON.pretty_generate(
  handle_api('getWalletAddress', {:wallet_id => '311111'}))
