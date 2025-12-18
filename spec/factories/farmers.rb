FactoryBot.define do
  factory :farmer do
    business_name { "#{Faker::Address.city} 농장" }
    owner_name { Faker::Name.name }
    sequence(:phone) { |n| "+8210#{format('%08d', n)}" }
    account_info { "농협 110-#{SecureRandom.hex(3)}-#{SecureRandom.hex(3)} 홍길동" }
    farmer_type { :type_a }
    approval_mode { :manual }
    notification_method { :kakao }
    stock_quantity { 0 }
    pin { "123456" }
  end
end
