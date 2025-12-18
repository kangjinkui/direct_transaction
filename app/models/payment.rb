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

  enum :verification_method,
       {
         phone_call: "phone_call",
         sms: "sms"
       }

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :verification_method, inclusion: { in: verification_methods.keys }, allow_nil: true
  validates :verification_method, presence: true, if: :verified?
end
