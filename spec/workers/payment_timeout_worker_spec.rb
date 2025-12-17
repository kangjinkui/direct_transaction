require "rails_helper"

RSpec.describe PaymentTimeoutWorker, type: :worker do
  let(:worker) { described_class.new }

  it "cancels payment_pending orders past timeout_at" do
    order = create(:order, status: :payment_pending, timeout_at: 1.hour.ago)

    worker.perform

    order.reload
    expect(order.status).to eq("cancelled")
    expect(order.cancelled_at).to be_present
  end

  it "does not cancel when timeout not reached" do
    order = create(:order, status: :payment_pending, timeout_at: 1.hour.from_now)

    worker.perform

    expect(order.reload.status).to eq("payment_pending")
  end
end
