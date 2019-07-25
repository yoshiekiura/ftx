module Samurai
  module Order
	  class << self

			def initialize()
			end

			def create(params = {})
				Samurai.post("/v1/pub/create", params)
			end
			
			def status(key)
				Samurai.get("/v1/pub/order?key=#{key}", {})
			end
		
	  end
  end
end
