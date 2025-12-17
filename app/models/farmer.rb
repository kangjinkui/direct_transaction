class Farmer < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :nullify

  has_secure_password :pin, validations: false

  enum :farmer_type, { type_a: "a", type_b: "b" }, validate: true, default: :type_a
  enum :notification_method, { kakao: "kakao", sms: "sms", auto: "auto" }, validate: true, default: :kakao
  enum :approval_mode, { manual: "manual", auto: "auto" }, validate: true, default: :manual, prefix: true

  validates :business_name, :owner_name, :phone, presence: true
  validates :phone, uniqueness: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def masked_phone
    return phone if phone.blank?

    phone.gsub(/(\d{4})(\d+)(\d{4})/, '\1****\3')
  end
end
