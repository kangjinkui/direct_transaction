class AdminOtpService
  CODE_LENGTH = 6
  TTL = 5.minutes

  Result = Struct.new(:status, :challenge, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def generate(purpose: "admin_login")
    code = format("%0#{CODE_LENGTH}d", SecureRandom.random_number(10**CODE_LENGTH))
    challenge = user.admin_otp_challenges.create!(
      code:,
      purpose:,
      expires_at: TTL.from_now
    )
    Result.new(status: :created, challenge:)
  end

  def verify(code, purpose: "admin_login")
    challenge = user.admin_otp_challenges.active.find_by(code:, purpose:)
    return Result.new(status: :not_found, challenge: nil) unless challenge

    AdminOtpChallenge.transaction do
      challenge.use!
      user.update!(last_otp_verified_at: Time.current)
    end

    Result.new(status: :verified, challenge:)
  end

  private

  attr_reader :user
end
