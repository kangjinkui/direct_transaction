require "rails_helper"

RSpec.describe Payment, type: :model do
  it "defaults to pending manual transfer" do
    payment = build(:payment)

    expect(payment).to be_pending
    expect(payment.payment_method).to eq("manual_transfer")
  end
end
