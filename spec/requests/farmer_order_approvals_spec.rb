require "rails_helper"

RSpec.describe "Farmer order approvals", type: :request do
  let(:farmer) { create(:farmer) }
  let(:user) { create(:user) }
  let(:product) { create(:product, farmer:, stock_quantity: 10, price: 12_000) }
  let(:order) { create(:order, farmer:, user:) }

  before do
    create(:order_item, order:, product:, quantity: 2, price: product.price)
  end

  def create_token(order:, expires_at: 1.hour.from_now, used_at: nil)
    OrderApprovalToken.create!(
      order:,
      token: SecureRandom.hex(8),
      expires_at:,
      used_at:,
      purpose: "farmer_approval"
    )
  end

  it "renders the approval page for active token" do
    token = create_token(order:)

    get farmer_approval_path(token.token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(order.order_number)
  end

  it "approves the order with a valid token" do
    token = create_token(order:)

    post approve_farmer_approval_path(token.token)

    expect(response).to redirect_to(farmer_approval_path(token.token))
    expect(order.reload.status).to eq("confirmed")
    expect(token.reload.used_at).to be_present
  end

  it "renders guard page for expired token" do
    token = create_token(order:, expires_at: 1.hour.ago)

    get farmer_approval_path(token.token)

    expect(response).to have_http_status(:gone)
  end

  it "renders guard page for used token" do
    token = create_token(order:, used_at: Time.current)

    get farmer_approval_path(token.token)

    expect(response).to have_http_status(:gone)
  end
end
