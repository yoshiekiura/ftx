class StratumAddress
  class << self
    def get_address(currency, eid)
      Rails.logger.info "Check Stratum address eid #{eid}, currency #{currency.code}"

      # Load from api, or create
      address = check_eid(eid,currency)
      address = generate_address(eid,currency) if address.nil? or address.empty?

      if address.nil? or address.empty?
        Rails.logger.error "Failed creating address eid #{eid}, currency #{currency.code}"
        raise StandardError.new( "Failed creating address eid #{eid}, currency #{currency.code}")
      end
      address
    end

    private

    def check_eid(eid, currency)
      address = nil
      payload = { wallet_id: currency[:stratum_wallet_id],
                  wallet_address_eid: eid }
      response = Stratum::Address.list(payload)
      if response.success? and response.has_key?('wallet_address',true)
        address = response.data[0]['wallet_address']
      end
      address
    rescue
      SystemMailer.address_generator_error(payload, $!.message, $!.backtrace.join("\n"))
      Rails.logger.error "Failed to process: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      nil
    end

    def check_info(address, currency)
      info = nil
      payload = { currency: currency.code.upcase,
                  wallet_address: address }
      response = Stratum::Address.get(payload)
      if response.success? and response.has_key?('wallet_address',false)
        info = response.data
      end
      info
    rescue
      SystemMailer.address_generator_error(payload, $!.message, $!.backtrace.join("\n")) unless Stratum.dev
      Rails.logger.error "Failed to process: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      nil
    end

    def generate_address(eid, currency)
      address = nil
      payload = { wallet_id: currency[:stratum_wallet_id],
                  wallet_address_eid: eid,
                  wallet_address_label: "#{currency.code}"
      }
      response = Stratum::Address.assign(payload)
      if response.success? and response.has_key?('wallet_address',false)
        address = response.data['wallet_address']
      else
        SystemMailer.address_generator_error(payload, response.message, response.inspect) unless Stratum.dev
      end
      address
    rescue
      SystemMailer.address_generator_error(payload, $!.message, $!.backtrace.join("\n")) unless Stratum.dev
      Rails.logger.error "Failed to process: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      nil
    end

  end
end
