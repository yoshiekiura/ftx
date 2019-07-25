module Stratum
  module Withdraw
	  class << self

			def initialize()
			end

			def crypto(params = {})
				Stratum.withdraw('crypto', params)
			end
		
	  end
  end
end
