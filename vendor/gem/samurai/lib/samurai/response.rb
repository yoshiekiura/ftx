module Samurai
  class Response 
  
    def initialize(response)
      @response = response
      parse
    end

		def status
			@status
		end

		def success?
			@status == :error ? false : true
		end

		def data
			@data
		end

		private

			def parse
				Samurai.logger.debug("#{self.class}:#{__method__} response:#{@response.inspect}")

				if @response.empty?
					@status = :not_found
				else
					@status = :ok

					response = MultiJson.decode(@response)
					if response.kind_of?(Array)
						@data = symbolize_first_level(response[0])
					else
						@data = symbolize_first_level(response)
					end
				end
			rescue
				Samurai.logger.error "Failed to parse: #{$!}"
				Samurai.logger.error $!.backtrace.join("\n")
			  @status = :error
			end

			def symbolize_first_level(hash)
				hash.inject({}) do |result, (key, value)|
					result[key.to_sym] = value
					result
				end
			end

  end
end
