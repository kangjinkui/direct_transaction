FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password!1" }
    password_confirmation { password }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
    address { Faker::Address.full_address }
    role { :user }

    trait :admin do
      role { :admin }
    end

    trait :staff do
      role { :staff }
    end
  end
end
