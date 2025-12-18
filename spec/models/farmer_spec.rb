require "rails_helper"

RSpec.describe Farmer, type: :model do
  describe "#account_info" do
    it "stores data encrypted and exposes masked helpers" do
      farmer = create(:farmer, account_info: "국민은행 123-456-789012 홍길동")

      expect(farmer.account_info).to eq("국민은행 123-456-789012 홍길동")
      expect(farmer.encrypted_account_info).to be_present
      expect(farmer.encrypted_account_info).not_to include("123-456")
      expect(farmer.account_last4).to eq("9012")
      expect(farmer.masked_account_info).to end_with("9012 홍길동")
      expect(farmer.masked_account_info).to include("*")
    end
  end
end
