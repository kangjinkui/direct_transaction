class OrderApprovalToken < ApplicationRecord
  belongs_to :order

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :purpose, presence: true

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
