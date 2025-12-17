require "rails_helper"

RSpec.describe AdminOtpService, type: :service do
  let(:user) { create(:user, role: :admin) }
  let(:service) { described_class.new(user) }

  describe "#generate" do
    it "creates a challenge with 6 digit code" do
      result = service.generate
      challenge = result.challenge

      expect(result.status).to eq(:created)
      expect(challenge.code.length).to eq(6)
      expect(challenge).to be_persisted
      expect(challenge.purpose).to eq("admin_login")
    end
  end

  describe "#verify" do
    it "returns not_found for wrong code" do
      service.generate
      result = service.verify("000000")

      expect(result.status).to eq(:not_found)
    end

    it "verifies and marks user" do
      created = service.generate
      code = created.challenge.code

      result = service.verify(code)
      expect(result.status).to eq(:verified)

      user.reload
      expect(user.last_otp_verified_at).to be_present
      expect(created.challenge.reload).to be_used
    end
  end
end
