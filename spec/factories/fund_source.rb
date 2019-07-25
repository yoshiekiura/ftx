FactoryGirl.define do
  factory :fund_source do
    extra 'bitcoin'
    uid { Faker::Bitcoin.address }
    is_locked false
    currency 'btc'

    member { create(:member) }

    trait :brl do
      extra '_001'
      uid '123412341234'
      currency 'brl'
    end

    trait :xrp do
      currency 'xrp'
      extra 'ripple'
      uid { Faker::Bitcoin.address }
      is_locked false
    end

    factory :brl_fund_source, traits: [:brl]
    factory :xrp_fund_source, traits: [:xrp]
    factory :btc_fund_source
  end
end

