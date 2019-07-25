module Stratum
  class Resource
    def initialize(client, path)
      @client = client
      @path = path
    end

    def get(params)
			Stratum.logger.debug("#{self.class}:#{__method__} params:#{params.inspect}")
			params = mark(params)
      create_request(:get, params).send_sync
    end

    def post(params)	  
			Stratum.logger.debug("#{self.class}:#{__method__} params:#{params.inspect}")
			params = mark(params)
      body = MultiJson.encode(params)
      create_request(:post, params, body).send_sync
    end

    private

    def create_request(verb, params, body = nil)
      Request.new(@client, verb, @path, params, body)
    end
	
	def system_time
	    @path == '/api/test/time' ? Time.now.to_i : ( Time.now.to_i - Stratum.offset )		
	end	
	
	def mark(params) 
		data = Hash.new
		data[:api_ts] = system_time
		data[:api_user] = @client.user				
		if params != 0 or false
		  data[:payload] = JSON.generate(params)
		end		
		data[:api_sig] = signature(data)
		
		return data
    end	
	
	def signature(data)		
		content = ''
		data.keys.sort
		data.each{ |key, value| content << "#{key}=#{value}&" }
		content = content[0...-1]

		OpenSSL::HMAC.hexdigest( OpenSSL::Digest::SHA256.new,
						         @client.secret,
						         content)
	end

  end
end
