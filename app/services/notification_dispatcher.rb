class NotificationDispatcher
  ProviderError = Class.new(StandardError)

  def initialize(primary:, fallback: nil)
    @primary = primary
    @fallback = fallback
  end

  # channel: "kakao" or "sms"
  def send!(order:, farmer:, notification_type:, channel: "kakao", metadata: {})
    notification = Notification.create!(
      order:,
      farmer:,
      notification_type:,
      channel: channel,
      status: :pending,
      token_jti: metadata[:token_jti],
      expires_at: metadata[:expires_at]
    )

    begin
      primary.deliver!(order:, farmer:, notification_type:, channel:, metadata:)
      notification.update!(status: :sent, sent_at: Time.current)
      :sent
    rescue StandardError
      raise unless fallback

      begin
        fallback.deliver!(order:, farmer:, notification_type:, channel: "sms", metadata:)
        notification.update!(channel: :sms, status: :sent, sent_at: Time.current)
        :fallback_sent
      rescue StandardError
        notification.update!(status: :failed)
        :failed
      end
    end
  end

  private

  attr_reader :primary, :fallback
end
