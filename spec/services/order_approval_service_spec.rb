require "rails_helper"

RSpec.describe OrderApprovalService, type: :service do
  let(:farmer_manual) { create(:farmer, approval_mode: :manual) }
  let(:farmer_auto) { create(:farmer, approval_mode: :auto) }
  let(:order_manual) { create(:order, farmer: farmer_manual) }
  let(:order_auto) { create(:order, farmer: farmer_auto) }

  before do
    create(:order_item, order: order_manual, product: create(:product, stock_quantity: 10), quantity: 2, price: 1000)
    create(:order_item, order: order_auto, product: create(:product, stock_quantity: 5), quantity: 3, price: 1000)
  end

  describe "#generate_token" do
    it "creates an approval token and moves to farmer_review if pending" do
      service = described_class.new(order_manual)
      result = service.generate_token

      expect(result.status).to eq(:generated)
      expect(order_manual).to be_farmer_review
      expect(result.token).to be_present
      expect(order_manual.order_approval_tokens.count).to eq(1)
    end
  end

  describe "#approve/#reject" do
    it "approves with valid token and deducts stock" do
      service = described_class.new(order_manual)
      token = service.generate_token.token.token

      result = service.approve(token: token)

      expect(result.status).to eq(:approved)
      expect(order_manual).to be_confirmed
      expect(order_manual.order_approval_tokens.first).to be_used
      expect(order_manual.order_items.first.product.stock_quantity).to eq(8)
    end

    it "rejects with valid token" do
      service = described_class.new(order_manual)
      token = service.generate_token.token.token

      result = service.reject(token: token)

      expect(result.status).to eq(:rejected)
      expect(order_manual).to be_rejected
      expect(order_manual.order_approval_tokens.first).to be_used
    end

    it "returns invalid_token for wrong token" do
      service = described_class.new(order_manual)
      service.generate_token

      result = service.approve(token: "bogus")
      expect(result.status).to eq(:invalid_token)
    end
  end

  describe "#auto_process!" do
    it "auto-confirms and deducts stock for auto farmers" do
      result = described_class.new(order_auto).auto_process!

      expect(result.status).to eq(:auto_confirmed)
      expect(order_auto).to be_confirmed
      expect(order_auto.order_items.first.product.stock_quantity).to eq(2)
    end

    it "rejects when stock is insufficient" do
      product = create(:product, stock_quantity: 1)
      order = create(:order, farmer: farmer_auto)
      create(:order_item, order:, product:, quantity: 3, price: 1000)

      result = described_class.new(order).auto_process!

      expect(result.status).to eq(:rejected_insufficient_stock)
      expect(order).to be_rejected
      expect(product.reload.stock_quantity).to eq(1)
    end
  end
end
