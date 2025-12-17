require "rails_helper"

RSpec.describe AdminOtpChallenge, type: :model do
  it "validates presence and length of code" do
    challenge = build(:admin_otp_challenge, code: "12345")
    expect(challenge).not_to be_valid
    expect(challenge.errors[:code]).to be_present
  end

  it "detects expiration" do
    challenge = build(:admin_otp_challenge, expires_at: 1.hour.ago)
    expect(challenge).to be_expired
  end

  it "marks used" do
    challenge = build(:admin_otp_challenge, used_at: nil)
    challenge.use!
    expect(challenge).to be_used
  end
end
