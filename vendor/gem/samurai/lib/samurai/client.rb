
module Samurai
  class Client
    attr_accessor :scheme, :host, :port
    attr_writer :connect_timeout, :send_timeout, :receive_timeout,
                :keep_alive_timeout

    ## CONFIGURATION ##
    def initialize(options = {})
      default_options = {
        :scheme => 'https',
        :port => 443,
      }
      merged_options = default_options.merge(options)

      @scheme, @host, @port, @user, @secret =
        merged_options.values_at(
          :scheme, :host, :port, :user, :secret
        )	

      # Default timeouts
      @connect_timeout = 5
      @send_timeout = 5
      @receive_timeout = 5
      @keep_alive_timeout = 30
    end

    def timeout=(value)
      @connect_timeout, @send_timeout, @receive_timeout = value, value, value
    end

    def configured?
      host && scheme && user && secret
    end


	  ## INTERACE WITH THE API ##

    def resource(path)	  
      Samurai.logger.debug("#{self.class}:#{__method__} host:#{@host} port:#{@port}")
	  
      Resource.new(self, path)	 
    end

    def get(path, params = {})	  
      resource(path).get(params)
    end

    def post(path, params = {})
      resource(path).post(params)
    end

    # @private Construct a net/http http client
    def sync_http_client
      @client ||= begin
        Net::HTTP::start(
            @host,
            @port,
            { use_ssl: true,
              opentimeout: @connect_timeout,
              continue_timeout: @send_timeout,
              read_timeout: @receive_timeout,
              keep_alive_timeout: @keep_alive_timeout } )
      end
    end
	
  end
end
