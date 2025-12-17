require "rails_helper"

RSpec.describe DailySummaryService, type: :service do
  let(:today) { Date.new(2025, 1, 20) }
  let(:farmer_auto) { create(:farmer, approval_mode: :auto) }
  let(:farmer_manual) { create(:farmer, approval_mode: :manual) }

  def create_order(farmer:, status:, total_amount:, created_at:)
    create(:order, farmer:, status:, total_amount:, created_at:)
  end

  it "sends one SMS per auto farmer with today's confirmed/payment orders" do
    create_order(farmer: farmer_auto, status: :confirmed, total_amount: 10_000, created_at: today.to_time + 9.hours)
    create_order(farmer: farmer_auto, status: :payment_pending, total_amount: 25_000, created_at: today.to_time + 11.hours)
    create_order(farmer: farmer_auto, status: :rejected, total_amount: 5_000, created_at: today.to_time + 12.hours)
    create_order(farmer: farmer_manual, status: :confirmed, total_amount: 50_000, created_at: today.to_time + 10.hours)
    create_order(farmer: farmer_auto, status: :confirmed, total_amount: 7_000, created_at: today.to_time - 1.day)

    described_class.new(date: today).deliver!

    expect(Notification.count).to eq(1)
    notification = Notification.last
    expect(notification.notification_type).to eq("daily_summary")
    expect(notification.channel).to eq("sms")
    expect(notification.farmer).to eq(farmer_auto)
    expect(notification.order).to be_nil
  end

  it "skips when there are no matching orders" do
    described_class.new(date: today).deliver!

    expect(Notification.count).to eq(0)
  end
end
