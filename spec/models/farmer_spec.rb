require "rails_helper"

RSpec.describe Farmer, type: :model do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:farmer)).to be_valid
    end

    it "requires unique phone" do
      farmer = create(:farmer, phone: "+821011111111")
      dup = build(:farmer, phone: farmer.phone)

      expect(dup).not_to be_valid
    end
  end

  describe "#masked_phone" do
    it "masks the middle digits" do
      farmer = build(:farmer, phone: "+821012345678")

      expect(farmer.masked_phone).to eq("+8210****5678")
    end
  end
end
