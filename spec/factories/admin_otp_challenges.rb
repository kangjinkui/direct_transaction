FactoryBot.define do
  factory :admin_otp_challenge do
    association :user
    code { "123456" }
    expires_at { 5.minutes.from_now }
    purpose { "admin_login" }
  end
end
