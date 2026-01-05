require "rails_helper"

RSpec.describe "Order cancellation", type: :request do
  let(:user) { create(:user) }
  let(:order) { create(:order, user:, status: :pending) }

  before do
    sign_in user
  end

  it "allows cancellation when pending" do
    post cancel_order_path(order)

    expect(response).to redirect_to(order_path(order))
    expect(order.reload.status).to eq("cancelled")
  end

  it "blocks cancellation when confirmed" do
    order.update!(status: :confirmed)

    post cancel_order_path(order)

    expect(response).to redirect_to(order_path(order))
    expect(order.reload.status).to eq("confirmed")
  end
end
