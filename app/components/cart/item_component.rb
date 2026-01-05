class Cart::ItemComponent < ViewComponent::Base
  def initialize(cart_item:)
    @cart_item = cart_item
  end

  private

  attr_reader :cart_item

  delegate :product, to: :cart_item
end
