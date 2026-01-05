class Farmer < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :nullify

  has_secure_password :pin, validations: false
  before_save :encrypt_account_info_data, if: :account_info_changed?

  enum :farmer_type, { type_a: "a", type_b: "b" }, validate: true, default: :type_a
  enum :notification_method, { kakao: "kakao", sms: "sms", auto: "auto" }, validate: true, default: :kakao
  enum :approval_mode, { manual: "manual", auto: "auto" }, validate: true, default: :manual, prefix: true

  validates :business_name, :owner_name, :phone, presence: true
  validates :phone, uniqueness: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Alias for business_name for convenience
  def name
    business_name
  end

  def location
    # TODO: Add location field to farmers table
    "위치 정보 없음"
  end

  def account_info=(value)
    @account_info = value
    @account_info_changed = true
  end

  def account_info
    return @account_info if instance_variable_defined?(:@account_info)

    @account_info = decrypt_account_info
  end

  def masked_phone
    return phone if phone.blank?

    phone.gsub(/(\d{4})(\d+)(\d{4})/, '\1****\3')
  end

  def masked_account_info
    info = account_info.to_s
    return "" if info.blank?

    digits = info.scan(/\d/)
    return info if digits.length <= 4

    digits_to_mask = digits.length - 4
    masked_digits = 0

    info.chars.map do |char|
      if char.match?(/\d/)
        masked_digits += 1
        masked_digits <= digits_to_mask ? "*" : char
      else
        char
      end
    end.join
  end

  def account_last4
    digits = account_info.to_s.gsub(/\D/, "")
    return "" if digits.blank?

    slice = digits[-4, 4]
    slice ? slice : digits
  end

  class << self
    def account_info_encryption_key
      key = ENV["ACCOUNT_INFO_KEY"] || Rails.application.credentials.dig(:account_info_key) || Rails.application.secret_key_base
      raise "ACCOUNT_INFO_KEY missing" if key.blank?

      key
    end

    def account_info_encryptor
      @account_info_encryptor ||= begin
        secret = ActiveSupport::KeyGenerator
                   .new(account_info_encryption_key)
                   .generate_key("farmer-account-info", ActiveSupport::MessageEncryptor.key_len)
        ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-gcm")
      end
    end
  end

  private

  def account_info_changed?
    @account_info_changed
  end

  def encrypt_account_info_data
    if account_info.present?
      self.encrypted_account_info = self.class.account_info_encryptor.encrypt_and_sign(account_info)
      # Store a unique marker even though we do not need the IV column to decrypt.
      self.encrypted_account_info_iv = SecureRandom.hex(12)
    else
      self.encrypted_account_info = ""
      self.encrypted_account_info_iv = ""
    end
    @account_info_changed = false
  end

  def decrypt_account_info
    return "" if encrypted_account_info.blank?

    self.class.account_info_encryptor.decrypt_and_verify(encrypted_account_info)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    ""
  end
end
