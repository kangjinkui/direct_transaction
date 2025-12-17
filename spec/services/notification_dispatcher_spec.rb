require "rails_helper"

RSpec.describe NotificationDispatcher, type: :service do
  let(:order) { create(:order) }
  let(:farmer) { order.farmer }
  let(:notification_type) { "farmer_approval" }
  let(:metadata) { { token_jti: "abc", expires_at: 30.minutes.from_now } }

  it "sends with primary provider" do
    primary = double(deliver!: true)
    dispatcher = described_class.new(primary:)

    result = dispatcher.send!(order:, farmer:, notification_type:, channel: "kakao", metadata:)

    expect(result).to eq(:sent)
    record = Notification.last
    expect(record.status).to eq("sent")
    expect(record.channel).to eq("kakao")
  end

  it "falls back to sms when primary raises" do
    primary = double
    allow(primary).to receive(:deliver!).and_raise("fail")
    fallback = double(deliver!: true)
    dispatcher = described_class.new(primary:, fallback:)

    result = dispatcher.send!(order:, farmer:, notification_type:, channel: "kakao", metadata:)

    expect(result).to eq(:fallback_sent)
    record = Notification.last
    expect(record.status).to eq("sent")
    expect(record.channel).to eq("sms")
  end

  it "marks failed when both providers raise" do
    primary = double
    allow(primary).to receive(:deliver!).and_raise("fail")
    fallback = double
    allow(fallback).to receive(:deliver!).and_raise("fail")
    dispatcher = described_class.new(primary:, fallback:)

    result = dispatcher.send!(order:, farmer:, notification_type:, channel: "kakao", metadata:)

    expect(result).to eq(:failed)
    expect(Notification.last.status).to eq("failed")
  end
end
