class Notification < ApplicationRecord
  belongs_to :order, optional: true
  belongs_to :farmer

  enum :channel, { kakao: "kakao", sms: "sms" }, validate: true, default: :kakao
  enum :status, { pending: "pending", sent: "sent", failed: "failed" }, validate: true, default: :pending

  validates :notification_type, presence: true
  validates :token_jti, uniqueness: true, allow_nil: true
end
