module Worker
  module Deposits
    module Slips

      class Tronipay
        # include NewRelic::Agent::Instrumentation::ControllerInstrumentation

        def initialize(deposit)
          @deposit = deposit
          @logger = Logger.new STDOUT
        end

        def process
          @logger.debug "Check deposit #{@deposit.txid}"

          return if @deposit.txid.nil?

          # Request INVOICE status
          status, content = info

          # lock second by day if waiting
          if status
            if content['status'] == '1' # PAID
              # Parse and set decimal format with 2 places
              tronipay_amount = sprintf("%.2f",content['amount'].to_d)
              cointrade_amount = sprintf("%.2f",@deposit.amount.to_d)

              if tronipay_amount == cointrade_amount
                @logger.debug "Accepted deposit #{@deposit.txid}"
                @deposit.charge!(@deposit.txid)
              else
                @logger.debug "Rejected deposit #{@deposit.txid}"
                @deposit.reject_it!(@deposit.txid)
              end
            else
              @logger.debug "Rejected deposit #{@deposit.txid}"
              @deposit.reject_it!(@deposit.txid)
            end
          else
            if content.include?( 'Dados Incorretos' )
              @logger.debug "Rejected deposit #{@deposit.txid}"
              @deposit.reject_it!(@deposit.txid)
            else
              @logger.warn "Tronipay status response: #{content.inspect}"
            end
          end

        end

        private
        def info
          status, content = request_content('/api/Boleto/VeryStatus', params)
          return status, content
        end

        def config
          @config || Slip.find_by_code('tronipay')
        end

        def params
          data = {}
          data[:invoice] = @deposit.txid
          data[:merchant_id] = config.merchant_id
          data[:sign] = Digest::SHA256.hexdigest("#{data[:invoice]}:#{data[:merchant_id]}")

          return data
        end

        def request_content(path, data)
          uri          = URI(config.host + path)
          http         = Net::HTTP.new(uri.host)
          request      = Net::HTTP::Post.new(uri.request_uri)
          request.body = URI.encode_www_form(data)
          result       = http.request(request)
          return true, MultiJson.decode(result.body)['Response'][0]
        rescue Exception => exception
          return false, exception.message
        end
        #
        # add_transaction_tracer :process, :category => :task

      end
    end
  end
end
