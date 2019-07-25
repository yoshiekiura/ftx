module APIv2
  module Auth
    module Utils
      class <<self

        def cache
          # Simply use rack-attack cache wrapper
          @cache ||= Rack::Attack::Cache.new
        end

        def urlsafe_string_40
          # 30 is picked so generated string length is 40
          SecureRandom.urlsafe_base64(30).tr('_-', 'xx')
        end

        alias :generate_access_key :urlsafe_string_40
        alias :generate_secret_key :urlsafe_string_40

        def hmac_signature(secret_key, payload)
          OpenSSL::HMAC.hexdigest 'SHA256', secret_key, payload
        end

        def check_stratum_signature( params )
          raise AuthorizationError if params[:api_sig].nil?

          # Validate request signature
          data = {}
          data[:api_ts] = params[:api_ts]
          data[:api_user] = Stratum.user
          data[:payload] = params[:payload]

          content = ''
          data.keys.sort
          data.each{ |key, value| content << "#{key}=#{value}&" }
          content = content[0...-1]
          authorized = params[:api_sig] == APIv2::Auth::Utils.hmac_signature(Stratum.secret, content)

          raise AuthorizationError unless authorized
        end

      end
    end
  end
end
