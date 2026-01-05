class Cart::FarmerSectionComponent < ViewComponent::Base
  def initialize(farmer:, cart_items:)
    @farmer = farmer
    @cart_items = cart_items
  end

  def total
    @cart_items.sum(&:subtotal)
  end

  private

  attr_reader :farmer, :cart_items
end
