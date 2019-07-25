require 'digest/md5'
require 'multi_json'

module Stratum
  class Request
    attr_reader :body, :params

    def initialize(client, verb, path, params, body = nil)
      @client, @verb, @path, @params = client, verb, path, params
      @head = {
        'X-Stratum-Library' => 'stratum-http-ruby ' + Stratum::VERSION
      }
    end

    def send_sync
	  Stratum.logger.info("#{self.class}:#{__method__} path:#{@path} @params:#{@params.inspect}")
      http = @client.sync_http_client

		  begin
		  # Define URI
		  uri = URI::HTTP.build({ host: @client.host,
		                          port: @client.port,
                                  path: @path,
								  scheme: @client.scheme,
								  })								  

		  # Configure request
		  request = Net::HTTP::Post.new(uri.request_uri)
		  request.set_form_data(@params)		 
		  
		  @head.each{ |key,value| request.add_field(key, value) }
		  
		  # Execute request
		  response = http.request(request)

      rescue Net::HTTPBadRequest, Net::HTTPRequestTimeOut,
             SocketError, Errno::ECONNREFUSED => e
        error = Stratum::HTTPError.new("#{e.message} (#{e.class})")
        error.original_error = e
        raise error
      end

      body = response.body ? response.body.chomp : nil

      return handle_response(response.code.to_i, body)
    end

    private
  
    def handle_response(status_code, body)
	    Stratum.logger.info("#{self.class}:#{__method__} path:#{@path} status_code:#{status_code.inspect}")
	
      case status_code
      when 200
        return Response.new(body)
      when 202
        return body.empty? ? true : Response.new(body)
      when 400
        raise Error, "Bad request: #{body}"
      when 401
        raise AuthenticationError, body
      when 404
        raise Error, "404 Not found (#{@path})"
      when 407
        raise Error, "Proxy Authentication Required"
      when 502
        raise Error, "Bad gateway"
      else
        raise Error, "Unknown error (status code #{status_code}): #{body}"
      end
    end

  end
end
