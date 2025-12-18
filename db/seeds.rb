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

puts "Seeding farmers..."
farmer_attrs = [
  { business_name: "Green Farm", owner_name: "Kim Farmer", phone: "+821011112222", farmer_type: :type_a },
  { business_name: "Sunny Orchard", owner_name: "Lee Grower", phone: "+821033344455", farmer_type: :type_b }
]

farmers = farmer_attrs.map do |attrs|
  Farmer.find_or_create_by!(phone: attrs[:phone]) do |farmer|
    farmer.business_name = attrs[:business_name]
    farmer.owner_name = attrs[:owner_name]
    farmer.farmer_type = attrs[:farmer_type]
    farmer.notification_method = attrs[:farmer_type] == :type_a ? :kakao : :auto
    farmer.account_info = "국민은행 123-456-789012 김파머"
    farmer.pin = "123456"
    farmer.stock_quantity = 500
  end
end

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
  order.policy_snapshot = { "approval_mode" => sample_farmer.type_a? ? "manual" : "auto" }
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

puts "Seed completed. Admin email: #{admin.email} / password: Password!1"
