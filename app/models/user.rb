require "ostruct"

class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable,
         :timeoutable,
         :omniauthable,
         omniauth_providers: %i[kakao naver]

  enum :role,
       {
         user: "user",
         admin: "admin",
         staff: "staff",
         viewer: "viewer",
         farmer: "farmer"
       },
       default: :user,
       validate: true

  validates :name, presence: true
  validates :role, presence: true
  validates :phone, uniqueness: true, allow_blank: true

  has_many :admin_otp_challenges, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_one :farmer_profile, class_name: "Farmer", foreign_key: :user_id, dependent: :destroy

  scope :admins, -> { where(role: %w[admin staff viewer]) }

  after_create :create_farmer_profile_if_farmer

  def create_farmer_profile_if_farmer
    return unless farmer?
    return if farmer_profile.present?

    create_farmer_profile!(
      business_name: name || "미설정",
      owner_name: name || "미설정",
      phone: phone || "미설정",
      approval_mode: :manual,
      notification_method: :kakao
    )
  end

  def needs_admin_otp?(window: 7.days)
    admin_like? && (last_otp_verified_at.nil? || last_otp_verified_at < window.ago)
  end

  def self.from_omniauth(auth)
    provider = auth.provider
    uid = auth.uid
    info = auth.info || OpenStruct.new

    find_or_initialize_by(oauth_provider: provider, oauth_uid: uid).tap do |user|
      user.email = info.email.presence || "#{provider}_#{uid}@example.com"
      user.name = info.name.presence || info.nickname || "사용자"
      user.phone ||= info.phone
      user.password ||= Devise.friendly_token.first(12)
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!) && auth.info&.verified
      user.save!
    end
  end

  def admin_like?
    %w[admin staff].include?(role)
  end

  def farmer?
    role == "farmer"
  end

  private
end
