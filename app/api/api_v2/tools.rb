module APIv2
  class Tools < Grape::API
    desc 'Get server current time, in seconds since Unix epoch.'
    get "/timestamp" do
      ::Time.now.to_i
    end

    desc 'Get HMAC signature from input params to QA', scopes: %w(trade)
    params do
      requires :secret_key, type: String,  default: 'wait', desc: "User secret key"
      requires :seed, type: String,  default: 'GET', desc: "Seed string to process in order to make checksum"
    end
    get "/signature" do
      if ENV['CSRF_SKIP_DOMAIN'].split(',').include?(env['SERVER_NAME'])
        secret_key = params['secret_key']
        seed = CGI::unescape( params['seed'] )

        present APIv2::Auth::Utils.hmac_signature(secret_key, seed)
      else
        raise AuthorizationError
      end
    end

    get "/stratum/deposit/count" do
      StratumEvent.where(operation_type: :deposit).all.count
    end

    get "/stratum/withdraw/count" do
      StratumEvent.where(operation_type: :withdraw).all.count
    end

    desc 'Update Stratum event.', scopes: %w(stratum)
    params do
      requires :api_ts, type: String, desc: "Source timestamp request"
      requires :payload, type: String, desc: "Key/Value entry details"
      requires :api_sig, type: String, desc: "API request signature"
    end
    post "/stratum/operation" do
      Rails.logger.info( params.inspect )

      APIv2::Auth::Utils.check_stratum_signature( params )

      # Locate event
      begin
        data = MultiJson.decode(params[:payload])
        data.symbolize_keys!

        event = StratumEvent.where(operation_id: data[:operation_id]).first
        raise EventByOperationIdNotFoundError, data[:operation_id] if event.nil?
      rescue
        raise EventByOperationIdNotFoundError, $!
      end

      # Update DB event
      begin
        # Update ONLY txid
        if data[:operation_etxid]
          event.operation_etxid = data[:operation_etxid]
          event.save!
        end
      rescue
        raise UpdateStratumEventError, $!
      end

      {status:true}
    end

  end
end
