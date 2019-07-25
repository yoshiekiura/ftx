module Worker
  require 'newrelic_rpm'

  class DepositCoinAddress
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def process(payload, metadata, delivery_info)
      @payload = payload

      payload.symbolize_keys!

      payment_address = PaymentAddress.find payload[:payment_address_id]
      return if payment_address.address.present? and !payment_address.address.nil? and !payment_address.address.empty?

      currency = payload[:currency]
      currency = Currency.find_by_code(currency.to_s)
      address = StratumAddress.get_address(currency, payment_address.id)

      if payment_address.update address: address
        ::Pusher["private-#{payment_address.account.member.sn}"].trigger_async('deposit_address', { type: 'create', attributes: payment_address.as_json})
      end
    end
      add_transaction_tracer :process, :category => :task
  end
end
