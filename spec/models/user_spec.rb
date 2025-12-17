require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject(:user) { build(:user) }

    it { expect(user).to be_valid }

    it "requires a name" do
      user.name = nil
      expect(user).not_to be_valid
    end

    it "sets default role" do
      user.save!
      expect(user.role).to eq("user")
    end
  end

  describe ".from_omniauth" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: "kakao",
        uid: SecureRandom.hex(4),
        info: OpenStruct.new(
          email: "oauth-user@example.com",
          name: "OAuth User",
          phone: "+821000000000"
        )
      )
    end

    it "creates a user with data from the provider" do
      user = described_class.from_omniauth(auth_hash)

      expect(user).to be_persisted
      expect(user.email).to eq("oauth-user@example.com")
      expect(user.oauth_provider).to eq("kakao")
    end

    it "returns existing user for the provider" do
      existing = described_class.from_omniauth(auth_hash)
      fetched = described_class.from_omniauth(auth_hash)

      expect(existing.id).to eq(fetched.id)
    end
  end
end
