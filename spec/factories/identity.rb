FactoryGirl.define do
  factory :identity do
    email { Faker::Internet.email }
    client_uuid { Faker::Number.number(8) }
    password { 'Password123' }
    password_confirmation { 'Password123' }
    is_active true

    trait :deactive do
      is_active false
    end
  end
end
