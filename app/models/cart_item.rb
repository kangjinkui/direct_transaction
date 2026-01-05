class CartItem < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :quantity_within_stock

  def subtotal
    product.price * quantity
  end

  private

  def quantity_within_stock
    return unless product && quantity

    if quantity > product.stock_quantity
      errors.add(:quantity, "재고 수량(#{product.stock_quantity})을 초과할 수 없습니다")
    end
  end
end
