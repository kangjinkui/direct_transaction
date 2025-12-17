require "rails_helper"

RSpec.describe Product, type: :model do
  it "has a valid factory" do
    expect(build(:product)).to be_valid
  end

  it "generates a sku if missing" do
    product = build(:product, sku: nil)
    product.validate

    expect(product.sku).to be_present
  end

  it "prevents duplicate sku" do
    product = create(:product)
    dup = build(:product, sku: product.sku)

    expect(dup).not_to be_valid
  end
end
