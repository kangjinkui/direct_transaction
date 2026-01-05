require "rails_helper"

RSpec.describe "Cart grouping", type: :request do
  let(:user) { create(:user) }
  let(:farmer_a) { create(:farmer) }
  let(:farmer_b) { create(:farmer) }
  let(:product_a) { create(:product, farmer: farmer_a) }
  let(:product_b) { create(:product, farmer: farmer_b) }

  before do
    create(:cart_item, user:, product: product_a, quantity: 1)
    create(:cart_item, user:, product: product_b, quantity: 2)
    sign_in user
  end

  it "renders farmer sections" do
    get cart_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(farmer_a.name)
    expect(response.body).to include(farmer_b.name)
  end
end
