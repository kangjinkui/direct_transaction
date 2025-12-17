class NotificationDispatchWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 1

  def perform(order_id, notification_type, channel = "kakao", metadata = {})
    order = Order.find(order_id)
    farmer = order.farmer
    dispatcher = NotificationDispatcher.new(
      primary: primary_provider(channel),
      fallback: fallback_provider(channel)
    )
    dispatcher.send!(
      order:,
      farmer:,
      notification_type:,
      channel: channel,
      metadata: metadata.symbolize_keys
    )
  end

  private

  def primary_provider(channel)
    case channel
    when "kakao"
      NotificationProviders::Kakao.new
    when "sms"
      NotificationProviders::Sms.new
    else
      NotificationProviders::Kakao.new
    end
  end

  def fallback_provider(channel)
    return NotificationProviders::Sms.new if channel == "kakao"

    nil
  end
end
