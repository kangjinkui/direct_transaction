require "rails_helper"

RSpec.describe "Order detail", type: :request do
  let(:user) { create(:user) }
  let(:farmer) { create(:farmer, account_info: "국민 123-456-7890") }
  let(:order) { create(:order, user:, farmer:, status: :payment_pending, total_amount: 25_000) }

  before do
    create(:order_item, order:, product: create(:product, farmer:, price: 12_500), quantity: 2, price: 12_500)
    sign_in user
  end

  it "shows masked account info and expandable full account" do
    get order_path(order)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(farmer.masked_account_info)
    expect(response.body).to include("전체 계좌 보기")
    expect(response.body).to include("123-456-7890")
  end

  it "shows report payment button only when payment_pending" do
    get order_path(order)

    expect(response.body).to include("입금 완료 신고")
  end

  it "hides report payment button when not payment_pending" do
    order.update!(status: :confirmed)

    get order_path(order)

    expect(response.body).not_to include("입금 완료 신고")
  end
end
