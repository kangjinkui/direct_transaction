require "rails_helper"

RSpec.describe Order, type: :model do
  describe "callbacks" do
    it "assigns order number" do
      order = create(:order)

      expect(order.order_number).to be_present
    end
  end

  describe "state machine" do
    it "transitions through payment flow" do
      order = create(:order)

      expect(order).to be_pending

      order.submit_for_review
      expect(order).to be_farmer_review

      order.confirm_order
      expect(order).to be_confirmed
    end

    it "supports cancellation" do
      order = create(:order)
      order.submit_for_review
      order.cancel_order

      expect(order).to be_cancelled
    end
  end

  describe "#with_idempotency" do
    it "applies a transition once per token" do
      order = create(:order)

      first = order.with_idempotency("tok-1") { order.submit_for_review! }
      expect(first).to eq(:applied)
      expect(order).to be_farmer_review

      second = order.with_idempotency("tok-1") { order.confirm_order! }
      expect(second).to eq(:duplicate)
      order.reload
      expect(order).to be_farmer_review

      third = order.with_idempotency("tok-2") { order.confirm_order! }
      expect(third).to eq(:applied)
      expect(order).to be_confirmed
    end

    it "requires a token" do
      order = build(:order)
      expect { order.with_idempotency(nil) { order.submit_for_review } }.to raise_error(ArgumentError)
    end
  end
end
