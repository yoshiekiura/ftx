module Private
  module Deposits
    module Slips
      class BaseController < ::Private::BaseController
        layout 'app'
        before_action :channel
        before_action :auth_activated!
        before_action :auth_verified!

        def channel
          @channel ||= DepositChannel.find_by_key(self.controller_name.singularize)
        end

        def model_kls
          "deposits/slips/#{self.controller_name.singularize}".camelize.constantize
        end

        def allow_forgery_protection
          return true
        end

      end
	end
  end
end

