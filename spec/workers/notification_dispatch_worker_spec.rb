require "rails_helper"

RSpec.describe NotificationDispatchWorker, type: :worker do
  let(:order) { create(:order) }
  let(:metadata) { { token_jti: "jti-1", expires_at: 30.minutes.from_now } }

  it "sends via primary provider" do
    expect_any_instance_of(NotificationProviders::Kakao).to receive(:deliver!).and_call_original

    described_class.new.perform(order.id, "farmer_approval", "kakao", metadata)

    expect(Notification.last.status).to eq("sent")
    expect(Notification.last.channel).to eq("kakao")
  end

  it "falls back to sms when kakao fails" do
    allow_any_instance_of(NotificationProviders::Kakao).to receive(:deliver!).and_raise("fail")
    expect_any_instance_of(NotificationProviders::Sms).to receive(:deliver!).and_call_original

    described_class.new.perform(order.id, "farmer_approval", "kakao", metadata)

    expect(Notification.last.status).to eq("sent")
    expect(Notification.last.channel).to eq("sms")
  end

  it "marks failed when both fail" do
    allow_any_instance_of(NotificationProviders::Kakao).to receive(:deliver!).and_raise("fail")
    allow_any_instance_of(NotificationProviders::Sms).to receive(:deliver!).and_raise("fail")

    described_class.new.perform(order.id, "farmer_approval", "kakao", metadata)

    expect(Notification.last.status).to eq("failed")
  end
end
