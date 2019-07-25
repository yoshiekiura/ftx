autoload 'Logger', 'logger'
require 'uri'
require 'forwardable'

require 'samurai/client'

module Samurai
  class Error < RuntimeError; end
  class AuthenticationError < Error; end
  class HTTPError < Error; attr_accessor :original_error; end

  class << self
    extend Forwardable
	
    def_delegators :default_client, :scheme, :host, :port, :http_proxy
    def_delegators :default_client, :scheme=, :host=, :user=, :secret=, :http_proxy=
    def_delegators :default_client, :timeout=, :connect_timeout=, :send_timeout=, :receive_timeout=, :keep_alive_timeout=

    def_delegators :default_client, :order, :post, :get

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
        cli = Samurai::Client
		    cli.new
      end
    end

  end
end

require 'samurai/version'
require 'samurai/request'
require 'samurai/resource'
require 'samurai/response'

require 'samurai/abstraction/order'
