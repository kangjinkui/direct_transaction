FactoryBot.define do
  factory :product do
    association :farmer
    sequence(:name) { |n| "상품 #{n}" }
    description { Faker::Food.description }
    price { rand(10_000..50_000) }
    category { "과일" }
    stock_quantity { 50 }
    stock_status { :available }
    is_available { true }
    max_per_order { 5 }
    sequence(:sku) { |n| "SKU-#{n}" }
  end
end
