module Private
  module Deposits
    module Slips
      require 'net/http'
      require 'uri'
      require 'json'
      class TronipaysController < ::Private::Deposits::Slips::BaseController
        include ::Deposits::CtrlSlipable

        def create
          @deposit = model_kls.new(deposit_params)

          if @deposit.save

            status, message = invoice(@deposit, params[:deposit][:slip])

            if status == true
              render json: { deposit: @deposit, message: message },
                     status: 200
            else
              @deposit.destroy

              render json: { deposit: @deposit, message: message },
                     status: 403
            end
          else
            render json: { message: @deposit.errors.full_messages.join },
                   status: 403
          end
        end

        private

        def invoice( deposit, client_details )
          require 'nokogiri'

          data = {}
          data[:mode] = '1'
          data[:amount] = deposit.amount.to_s
          data[:url_retorn] = request.env['REQUEST_URI']
          data[:description] = I18n.t('deposit_channel.bank.slip.tax_percent')
          data[:currency] = '1'
          data[:invoice] = deposit.txid
          data[:merchant_id] = config.merchant_id
          data[:email] = current_user.email
          data[:sign] = Digest::SHA256.hexdigest("#{deposit.txid}:#{config.merchant_id}:#{'1'}")


          remap_keys = { name: :person_name,
                         cpf: :person_doc,
                         phone: :phone,
                         city: :city,
                         address: :address_name,
                         state: :state,
                         zip: :postal_code }

          remap_keys.each{ |key,value| data[key] = client_details[value.to_s] }
          data
          content = request_content('/api/Boleto/Create2', data)
          if content.nil?
            return false , I18n.t('funds.deposit_brl.message_validation2')
          end
          ret_link = content[1]['Response'][0]['linkboleto']
          status = content[1]['Response'][0]['status']

          if status != '200'
           return false, I18n.t('funds.deposit_brl.message_validation2')
          else
            deposit.fund_extra = ret_link
            deposit.save
            return true, ret_link
          end

        end

        def params_start(deposit, client_details)
          data = {}
          data[:mode] = '1'
          data[:amount] = deposit.amount.to_s
          data[:url_retorn] = request.env['REQUEST_URI']
          data[:description] = I18n.t('deposit_channel.bank.slip.tax_percent')
          data[:currency] = '1'
          data[:invoice] = deposit.txid
          data[:merchant_id] = config.merchant_id
          data[:email] = current_user.email

          remap_keys = { nome: :person_name,
                         cpfcnpj: :person_doc,
                         telefone: :phone,
                         endereco: :address_name,
                         cidade: :city,
                         numero: :address_number,
                         uf: :state,
                         cep: :postal_code }

          remap_keys.each{ |key,value| data[key] = client_details[value.to_s] }

          data
        end

        def params_merge(deposit, client_details, content)
          page = Nokogiri::HTML(content)

          data = {}
          inputs = page.search('input')
          inputs.each do |node|
            data[node['name']] = node['value']
          end
          return data
        end

        def request_content(path, data)
          uri          = URI(config.host + path)
          http         = Net::HTTP.new(uri.host)
          request      = Net::HTTP::Post.new(uri.request_uri)
          request.body = URI.encode_www_form(data)
          result       = http.request(request)
          return true, JSON.parse(result.body)
        rescue Exception => exception
          return false, exception.message
        end
        #
        # def validate_content(data)
        #
        #   if  data[1]['Response']
        #
        #     return true, ''
        #   else
        #     if content.include?('alert("')
        #       blocks = content.split('alert("')
        #       message = blocks[1].split('")')[0]
        #       return false, message
        #     else
        #       return false, I18n.t('funds.deposit_brl.message_validation')
        #     end
        #   end
        # end

        def extract_url(content)
          page = Nokogiri::HTML(content)
          url = ''
          inputs = page.search('iframe')
          inputs.each do |node|
            url = node['src']
          end
          return url
        end

        def config
          @config || Slip.find_by_code('tronipay')
        end

      end
    end
  end
end

