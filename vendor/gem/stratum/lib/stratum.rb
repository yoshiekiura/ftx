autoload 'Logger', 'logger'
require 'uri'
require 'forwardable'

require 'stratum/client'

module Stratum
  class Error < RuntimeError; end
  class AuthenticationError < Error; end
  class ConfigurationError < Error
    def initialize(key)
      super "missing key `#{key}' in the client configuration"
    end
  end
  class HTTPError < Error; attr_accessor :original_error; end

  class << self
    extend Forwardable
	
    def_delegators :default_client, :scheme, :host, :port, :user, :secret, :http_proxy, :dev
    def_delegators :default_client, :scheme=, :host=, :user=, :secret=, :http_proxy=, :dev=
    def_delegators :default_client, :timeout=, :connect_timeout=, :send_timeout=, :receive_timeout=, :keep_alive_timeout=

    def_delegators :default_client, :time, :offset, :wallet, :wallet_group, :address, :withdraw, :operation

    attr_writer :logger

    def logger
      @logger ||= begin
        log = Logger.new($stdout)
        log.level = Logger::INFO
        log
      end
    end

    def default_client
      @default_client ||= begin	    
        cli = Stratum::Client
		cli.new
      end
    end

  end
end

require 'stratum/version'
require 'stratum/request'
require 'stratum/resource'
require 'stratum/response'

require 'stratum/abstraction/wallet'
require 'stratum/abstraction/wallet_group'
require 'stratum/abstraction/address'
require 'stratum/abstraction/withdraw'
require 'stratum/abstraction/operation'
