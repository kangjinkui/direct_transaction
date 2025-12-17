FactoryBot.define do
  factory :order do
    association :user
    association :farmer
    total_amount { 25_000 }
    status { :pending }
    sequence(:order_number) { |n| "ORD-20250101-#{format('%03d', n)}" }
    policy_snapshot { { "approval_mode" => "manual" } }
    status_history { [] }

    trait :confirmed do
      status { :confirmed }
      confirmed_at { Time.current }
    end
  end
end
