module Stratum
  class Response 
  
    def initialize(response)
      @response = response
	  	parse
    end
	
		def success?
			@status == 'ok' ? true : false
		end
		
		def has_key?(key, is_array = false )
			if is_array
			  @data.size > 0 and !@data[0].nil? and !@data[0][key].nil?
			else
              @data.size > 0 and !@data[key].nil?
			end 
		end

		def status
			@status
		end

		def message
			@message
		end

		def data
			@data
		end

		private

			def parse
				Stratum.logger.debug("#{self.class}:#{__method__} response:#{@response.inspect}")

				response = symbolize_first_level(MultiJson.decode(@response))
				@status = response[:status]
				@message = response[:message]
				@data = response[:data]
			end

			def symbolize_first_level(hash)
				hash.inject({}) do |result, (key, value)|
					result[key.to_sym] = value
					result
				end
			end

  end
end
