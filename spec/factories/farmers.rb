FactoryBot.define do
  factory :farmer do
    business_name { "#{Faker::Address.city} 농장" }
    owner_name { Faker::Name.name }
    sequence(:phone) { |n| "+8210#{format('%08d', n)}" }
    account_info_enc { "enc-#{SecureRandom.hex(8)}" }
    encrypted_account_info { "enc-#{SecureRandom.hex(6)}" }
    farmer_type { :type_a }
    approval_mode { :manual }
    notification_method { :kakao }
    stock_quantity { 0 }
    pin { "123456" }
  end
end
