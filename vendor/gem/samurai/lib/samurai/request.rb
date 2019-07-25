require 'digest/md5'
require 'multi_json'

module Samurai
  class Request
    attr_reader :body, :params

    def initialize(client, verb, path, params, body = nil)
      @client, @verb, @path, @params, @body = client, verb, path, params, body
      @head = {
        'X-Samurai-Library' => 'samurai-http-ruby ' + Samurai::VERSION,
        'Authorization' => ENV['SAMURAI_AUTHORIZATION']
      }
    end

    def send_sync
	    Samurai.logger.info("#{self.class}:#{__method__} path:#{@path} @params:#{@params.inspect}")
      http = @client.sync_http_client

		  begin

        # Configure request
        if @verb == :post
          uri = URI::HTTP.build({ host: @client.host,
                                  port: @client.port,
                                  path: @path,
                                  scheme: @client.scheme,
                                })

          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data(@params)
          request.body = @body
        else
          uri = URI("#{@client.scheme}://#{@client.host}#{@path}")

          request = Net::HTTP::Get.new(uri)
        end

        @head.each{ |key,value| request.add_field(key, value) }

        # Execute request
        response = http.request(request)

      rescue Net::HTTPBadRequest, Net::HTTPRequestTimeOut,
             SocketError, Errno::ECONNREFUSED => e
        error = Samurai::HTTPError.new("#{e.message} (#{e.class})")
        error.original_error = e
        raise error
      end

      body = response.body ? response.body.chomp : nil

      return handle_response(response.code.to_i, body)
    end

    private
  
    def handle_response(status_code, body)
	    Samurai.logger.info("#{self.class}:#{__method__} path:#{@path} status_code:#{status_code.inspect}")
	
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
