FactoryBot.define do
  factory :payment do
    association :order
    payment_method { :manual_transfer }
    amount { 25_000 }
    status { :pending }
    reference { "입금확인#{SecureRandom.hex(2)}" }
    admin_note { nil }
  end
end
