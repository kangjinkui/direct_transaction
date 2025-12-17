require "rails_helper"

RSpec.describe OrderTimeoutWorker, type: :worker do
  let(:worker) { described_class.new }

  it "cancels pending or farmer_review orders past timeout_at" do
    order = create(:order, status: :farmer_review, timeout_at: 1.hour.ago)

    worker.perform

    order.reload
    expect(order.status).to eq("cancelled")
    expect(order.cancelled_at).to be_present
  end

  it "does not cancel orders that are not timed out" do
    order = create(:order, status: :farmer_review, timeout_at: 1.hour.from_now)

    worker.perform

    expect(order.reload.status).to eq("farmer_review")
  end
end
