module Stratum
  module Wallet 
	  class << self

			def initialize()
			end

			def list(params = {})
				Stratum.wallet('list', params)
			end

			def get(params = {})
				Stratum.wallet('get', params)
			end
			
			def create(params = {})
				Stratum.wallet('create', params)
			end

			def delete(params = {})
				Stratum.wallet('delete', params)
			end
		
	  end
  end
end
