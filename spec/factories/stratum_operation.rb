FactoryGirl.define do
  factory :stratum_event do
    operation_id {1}
    operation_etxid { Faker::Lorem.characters(16) }
    operation_status :done
    cointrade_state :waiting
    dest_type :address
    dest_type_data "{ 'wallet_address': '#{Faker::Bitcoin.address}' }"
  end
end

