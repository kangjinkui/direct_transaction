FactoryBot.define do
  factory :notification do
    association :order
    association :farmer
    notification_type { "order_status" }
    channel { :kakao }
    status { :pending }
    token_jti { SecureRandom.uuid }
    sent_at { nil }
    used_at { nil }
    expires_at { 30.minutes.from_now }
  end
end
