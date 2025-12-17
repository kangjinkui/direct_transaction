require "rails_helper"

RSpec.describe "Order flow", type: :system do
  include Warden::Test::Helpers

  before do
    Warden.test_mode!
    driven_by(:rack_test)
  end

  after do
    Warden.test_reset!
  end

  it "allows user to create order, farmer approve, and admin verify payment" do
    user = create(:user, password: "Password!1", password_confirmation: "Password!1")
    farmer = create(:farmer, approval_mode: :manual, stock_quantity: 10)
    product = create(:product, farmer:, stock_quantity: 5, is_available: true)
    admin = create(:user, :admin, password: "Password!1", password_confirmation: "Password!1", last_otp_verified_at: Time.current)

    # User signs in (bypass UI)
    login_as(user, scope: :user)

    # Create order via direct factory (no UI flow implemented)
    order = create(:order, user:, farmer:, status: :farmer_review, total_amount: 10000)
    create(:order_item, order:, product:, quantity: 2, price: 5000)

    # Farmer approves via service (simulating approval link)
    approval = OrderApprovalService.new(order).generate_token
    OrderApprovalService.new(order).approve(token: approval.token.token)
    order.reload
    expect(order.status).to eq("confirmed")

    # Admin verifies payment
    login_as(admin, scope: :user)
    payment = PaymentService.new(order).report_transfer(amount: order.total_amount, reference: "TEST-REF").payment
    result = PaymentService.new(order).verify!(verified_at: Time.current, admin_note: "Test")
    expect(result.status).to eq(:completed)
    expect(order.reload.status).to eq("completed")
    expect(payment.reload.status).to eq("verified")
  end
end
