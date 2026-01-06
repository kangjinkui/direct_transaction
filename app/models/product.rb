class Product < ApplicationRecord
  belongs_to :farmer
  has_many :order_items, dependent: :restrict_with_exception

  enum :stock_status,
       {
         available: "available",
         low: "low",
         sold_out: "sold_out",
         inquire: "inquire"
       },
       default: :available,
       validate: true

  before_validation :ensure_sku

  validates :name, :price, :stock_quantity, :max_per_order, :sku, presence: true
  validates :price, :stock_quantity, :max_per_order, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: true

  scope :available_for_sale, -> { where.not(stock_status: :sold_out) }
  scope :available, -> { where(is_available: true) }

  def in_stock?
    is_available && stock_quantity.to_i.positive? && stock_status != "sold_out"
  end

  def image_url
    nil
  end

  private

  def ensure_sku
    self.sku ||= "SKU-#{SecureRandom.hex(4).upcase}"
  end
end
