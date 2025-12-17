require "rails_helper"

RSpec.describe OrderItem, type: :model do
  it "calculates line total" do
    item = build(:order_item, quantity: 3, price: 10_000)

    expect(item.line_total).to eq(30_000)
  end
end
