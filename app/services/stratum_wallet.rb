class StratumWallet
  class << self
    def get_id(eid,group_id,currency)
      Rails.logger.info "Check Stratum wallet eid #{eid}, group_id #{group_id} currency #{currency.code}"

      # Load from api, or create
      wallet_eid = check_eid(eid, group_id, currency)
      wallet_eid = generate_eid(eid, group_id, currency) if wallet_eid.nil?

      if wallet_eid.nil?
        Rails.logger.error "Failed creating wallet eid #{eid}, currency #{currency.code}"
        raise StandardError.new( "Failed creating wallet eid #{eid}, currency #{currency.code}")
      end
      wallet_eid
    end

    def get_balance(id)
      balance = 0
      payload = { wallet_id: id }

      response = Stratum::Wallet.get(payload)
      if response.success? and response.has_key?('wallet_balance',false)
        balance = response.data['wallet_balance'].to_d
      end
      balance
    rescue
      Rails.logger.error "Failed to process: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      0
    end

    private

    def check_eid(eid, group_id, currency)
      id = nil
      payload = { currency: currency.code.upcase,
                  currency_type: 'crypto',
                  wallet_eid: eid,
                  wallet_group_id: group_id,
                  wallet_type: 'checking'
      }

      response = Stratum::Wallet.list(payload)
      if response.success? and response.has_key?('wallet_id',true)
        id = response.data[0]['wallet_id'].to_i
      end
      id
    rescue
      SystemMailer.wallet_mapping_error(payload, $!.message, $!.backtrace.join("\n"))
      Rails.logger.error "Failed to process: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      nil
    end

    def generate_eid(eid, group_id, currency)
      id = nil
      payload = { currency: currency.code.upcase,
                  wallet_eid: eid,
                  wallet_group_id: group_id,
                  wallet_label: "wallet currency #{currency.code}",
                  wallet_type: 'checking'
      }

      response = Stratum::Wallet.create(payload)
      if response.success? and response.has_key?('wallet_id',false)
        id = response.data['wallet_id'].to_i
      else
        SystemMailer.wallet_mapping_error(payload, response.message, response.inspect)
      end
      id
    rescue
      SystemMailer.wallet_mapping_error(payload, $!.message, $!.backtrace.join("\n"))
      Rails.logger.error "Failed to process: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
      nil
    end

  end
end
