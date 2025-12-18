require "rails_helper"

RSpec.describe OrderAutoProcessWorker, type: :worker do
  before do
    allow(OrderAutoProcessWorker).to receive(:perform_async)
  end

  describe "#perform" do
    let(:farmer) { create(:farmer, approval_mode: :auto) }
    let(:product) { create(:product, farmer:, stock_quantity: 5) }

    it "auto-confirms pending orders when stock is sufficient" do
      order = create(:order, farmer:, status: :pending)
      create(:order_item, order:, product:, quantity: 2, price: 1000)

      described_class.new.perform(order.id)

      expect(order.reload).to be_confirmed
      expect(product.reload.stock_quantity).to eq(3)
      expect(Notification.count).to eq(0)
    end

    it "rejects and notifies when stock is insufficient" do
      product.update!(stock_quantity: 1)
      order = create(:order, farmer:, status: :pending)
      create(:order_item, order:, product:, quantity: 3, price: 1000)

      expect do
        described_class.new.perform(order.id)
      end.to change(Notification, :count).by(1)

      order.reload
      notification = Notification.last
      expect(order).to be_rejected
      expect(notification.notification_type).to eq("stock_depleted")
      expect(notification.channel).to eq("kakao")
    end

    it "ignores non-auto farmers" do
      manual_farmer = create(:farmer, approval_mode: :manual)
      manual_order = create(:order, farmer: manual_farmer, status: :pending)

      expect do
        described_class.new.perform(manual_order.id)
      end.not_to change { manual_order.reload.status }
    end
  end
end
