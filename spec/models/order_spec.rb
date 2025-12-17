require "rails_helper"

RSpec.describe Order, type: :model do
  include ActiveSupport::Testing::TimeHelpers

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

  describe "status change tracking" do
    it "records status_history and last_status_changed_* with actor" do
      admin = create(:user, :admin)
      order = create(:order)
      freeze_time = Time.current.change(usec: 0)

      travel_to(freeze_time) do
        order.status_changed_by = admin
        order.submit_for_review!
      end
      order.reload

      last_entry = order.status_history.last
      expect(last_entry["status"]).to eq("farmer_review")
      expect(last_entry["by_id"]).to eq(admin.id)
      expect(last_entry["by_type"]).to eq("User")
      expect(order.last_status_changed_at).to eq(freeze_time)
      expect(order.last_status_changed_by_id).to eq(admin.id)
      expect(order.last_status_changed_by_type).to eq("User")
    end

    it "records change without actor" do
      order = create(:order)

      travel_to(Time.current + 1.hour) do
        order.submit_for_review!
      end
      order.reload

      last_entry = order.status_history.last
      expect(last_entry["by_id"]).to be_nil
      expect(last_entry["by_type"]).to be_nil
      expect(order.last_status_changed_by_id).to be_nil
      expect(order.last_status_changed_by_type).to be_nil
    end
  end
end
