module Stratum
  module Address 
	  class << self

			def initialize()
			end

			def list(params = {})
				Stratum.address('list', params)
			end
			
			def get(params = {})
				Stratum.address('get', params)
			end

			def assign(params = {})
				Stratum.address('assign', params)
			end
		
	  end
  end
end
