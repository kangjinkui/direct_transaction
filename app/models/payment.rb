class Payment < ApplicationRecord
  belongs_to :order

  enum :status,
       {
         pending: "pending",
         verified: "verified"
       },
       default: :pending,
       validate: true

  enum :payment_method,
       {
         manual_transfer: "manual_transfer",
         pg: "pg"
       },
       default: :manual_transfer,
       validate: true

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
