module Stratum
  module Operation 
	  class << self

			def initialize()
			end

			# payload (as filter)
            #   operation_type = withdraw
            #   currency = code of currency ('btc')
            #   dest_type = address
			def fees(params = {})
				Stratum.operation('fees', params)
			end

			def list(params = {})
				Stratum.operation('list', params)
			end
			
			def send_to_address(params = {})
				Stratum.operation('sendtoaddress', params)
			end

			def send_to_wallet(params = {})
				Stratum.operation('sendtowallet', params)
			end

			def deposit(params = {})
				Stratum.operation('deposit', params)
			end
			
	  end
  end
end
