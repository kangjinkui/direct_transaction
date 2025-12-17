class AdminOtpChallenge < ApplicationRecord
  belongs_to :user

  validates :code, presence: true, length: { is: 6 }
  validates :purpose, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def used?
    used_at.present?
  end

  def use!
    update!(used_at: Time.current)
  end
end
