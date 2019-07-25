
module Stratum
  class Client
    attr_accessor :scheme, :host, :port, :user, :secret, :dev
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

    def offset
      @offset ||= begin
        Stratum.logger.debug("#{self.class}:#{__method__} Define offset")
        response = time
        offset = 0
        if response.success?
          external_time = response.data["time"].to_i
          system_time = Time.now.to_i
          offset = system_time - external_time
        end

        offset
      end
    end
	
	  ## Endpoints RAW way ##

    def time
      post("/api/test/time", {})
    end

    def wallet_group(action, params = {})
      post("/api/walletGroups/#{action}", params)
    end
	
    def wallet(action, params = {})
      post("/api/wallets/#{action}", params)
    end
	
    def address(action, params = {})
      post("/api/walletAddresses/#{action}", params)
    end
	
    def withdraw(action, params = {})
      post("/api/withdraws/#{action}", params)
    end
	
    def operation(action, params = {})
      post("/api/operations/#{action}", params)
    end
	
    ## INTERACE WITH THE API ##

    def resource(path)	  
      Stratum.logger.debug("#{self.class}:#{__method__} host:#{@host} port:#{@port} user:#{@user}")
	  
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
