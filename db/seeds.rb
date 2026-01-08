require "securerandom"

puts "Seeding users..."
admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Admin"
  user.password = "Password!1"
  user.password_confirmation = "Password!1"
  user.phone = "+821012345678"
  user.address = "Seoul, Jongno-gu 1"
  user.role = :admin
end

consumer = User.find_or_create_by!(email: "consumer@example.com") do |user|
  user.name = "Consumer"
  user.password = "Password!1"
  user.password_confirmation = "Password!1"
  user.phone = "+821055566677"
  user.address = "Seoul, Mapo-gu 10"
  user.role = :user
end

puts "Seeding farmer users..."
# Farmer login accounts
farmer_user_1 = User.find_or_initialize_by(email: "farmer1@example.com")
farmer_user_1.assign_attributes(
  name: "Green Farm",
  password: "Password!1",
  password_confirmation: "Password!1",
  phone: "+821011112222",
  role: :farmer
)
farmer_user_1.save!
farmer_user_1.create_farmer_profile_if_farmer if farmer_user_1.farmer_profile.nil?

farmer_user_2 = User.find_or_initialize_by(email: "farmer2@example.com")
farmer_user_2.assign_attributes(
  name: "Sunny Orchard",
  password: "Password!1",
  password_confirmation: "Password!1",
  phone: "+821033344455",
  role: :farmer
)
farmer_user_2.save!
farmer_user_2.create_farmer_profile_if_farmer if farmer_user_2.farmer_profile.nil?

puts "Updating farmer profiles..."
# 농가 프로필 업데이트 (User 모델의 after_create로 자동 생성됨)
if farmer_user_1.farmer_profile
  farmer_user_1.farmer_profile.update!(
    business_name: "Green Farm",
    owner_name: "Kim Farmer",
    farmer_type: :type_a,
    approval_mode: :manual,
    notification_method: :kakao,
    account_info: "국민은행 123-456-789012 김파머",
    pin: "123456",
    stock_quantity: 500
  )
end

if farmer_user_2.farmer_profile
  farmer_user_2.farmer_profile.update!(
    business_name: "Sunny Orchard",
    owner_name: "Lee Grower",
    farmer_type: :type_b,
    approval_mode: :auto,
    notification_method: :sms,
    account_info: "농협 987-654-321098 이재배",
    pin: "123456",
    stock_quantity: 500
  )
end

farmers = [farmer_user_1.farmer_profile, farmer_user_2.farmer_profile]

puts "Seeding products..."
farmers.each do |farmer|
  [
    { name: "#{farmer.business_name} Lettuce Box", category: "vegetable", price: 35_000 },
    { name: "#{farmer.business_name} Apple Mix", category: "fruit", price: 28_000 }
  ].each do |product_attrs|
    Product.find_or_create_by!(farmer:, name: product_attrs[:name]) do |product|
      product.description = "#{product.name} sample item"
      product.category = product_attrs[:category]
      product.price = product_attrs[:price]
      product.stock_quantity = 100
      product.max_per_order = 3
      product.stock_status = :available
    end
  end
end

puts "Seeding sample order..."
sample_farmer = farmers.first
sample_order = Order.find_or_create_by!(order_number: "ORD-SEED-001") do |order|
  order.user = consumer
  order.farmer = sample_farmer
  order.total_amount = 70_000
  order.status = :pending
  order.shipping_name = consumer.name
  order.shipping_phone = consumer.phone
  order.shipping_address = consumer.address
  order.shipping_zip_code = "12345"
  order.delivery_memo = "문 앞에 놓아주세요"
  order.policy_snapshot = { "approval_mode" => sample_farmer.approval_mode }
end

if sample_order.order_items.none?
  sample_product = sample_farmer.products.first
  sample_order.order_items.create!(
    product: sample_product,
    quantity: 2,
    price: sample_product.price
  )
end

Payment.find_or_create_by!(order: sample_order) do |payment|
  payment.amount = sample_order.total_amount
  payment.status = :pending
  payment.payment_method = :manual_transfer
end

puts "=" * 80
puts "Seed completed!"
puts "=" * 80
puts "Admin:"
puts "  Email: #{admin.email}"
puts "  Password: Password!1"
puts ""
puts "Consumer:"
puts "  Email: #{consumer.email}"
puts "  Password: Password!1"
puts ""
puts "Farmer 1 (수동 승인):"
puts "  Email: farmer1@example.com"
puts "  Password: Password!1"
puts "  Business: Green Farm"
puts ""
puts "Farmer 2 (자동 승인):"
puts "  Email: farmer2@example.com"
puts "  Password: Password!1"
puts "  Business: Sunny Orchard"
puts "=" * 80
