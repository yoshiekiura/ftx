module Samurai
  class Resource
    def initialize(client, path)
      @client = client
      @path = path
    end

    def get(params)
	    Samurai.logger.debug("#{self.class}:#{__method__} params:#{params.inspect}")
      create_request(:get, params).send_sync
    end

    def post(params)	  
	    Samurai.logger.debug("#{self.class}:#{__method__} params:#{params.inspect}")
      body = params
      create_request(:post, {}, body).send_sync
    end

    private

    def create_request(verb, params, body = nil)
      Request.new(@client, verb, @path, params, body)
    end
	
  end
end
