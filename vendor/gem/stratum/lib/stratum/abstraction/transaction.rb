module Stratum
  module Transaction 
	  class << self

			def initialize()
			end

			def list(params = {})
				Stratum.transaction('list', params)
			end
		
	  end
  end
end
