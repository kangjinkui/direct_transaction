class OrderTransitionToken < ApplicationRecord
  belongs_to :order

  validates :token, presence: true, uniqueness: { scope: :order_id }
end
