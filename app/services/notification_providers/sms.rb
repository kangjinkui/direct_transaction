require "net/http"
require "uri"
require "json"

module NotificationProviders
  class Sms
    class MissingConfig < StandardError; end

    def deliver!(order:, farmer:, notification_type:, channel:, metadata: {})
      raise "sms_failed" if metadata[:force_sms_fail]
      return true if Rails.env.test? && !metadata[:force_network]

      to = metadata[:recipient_phone].presence || farmer&.phone
      raise MissingConfig, "SMS recipient missing" if to.blank?

      message = metadata[:message] || default_message(notification_type, order:, metadata:)
      raise MissingConfig, "SMS message missing" if message.blank?

      ensure_config_present!
      perform_delivery(
        to: to,
        from: sms_sender_id,
        body: message
      )
    end

    private

    def default_message(notification_type, order:, metadata:)
      case notification_type
      when "farmer_approval"
        order_number = order&.order_number || metadata[:order_number]
        "Order #{order_number} requires your approval."
      when "order_status"
        status = order&.status || metadata[:status]
        "Order #{order&.order_number || metadata[:order_number]} status: #{status}."
      else
        metadata[:message] || "Notification: #{notification_type}"
      end
    end

    def perform_delivery(payload)
      uri = URI.parse(sms_api_url)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{sms_api_key}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      raise "sms_failed" unless response.is_a?(Net::HTTPSuccess)

      true
    end

    def ensure_config_present!
      raise MissingConfig, "SMS_API_URL missing" if sms_api_url.blank?
      raise MissingConfig, "SMS_API_KEY missing" if sms_api_key.blank?
      raise MissingConfig, "SMS_SENDER_ID missing" if sms_sender_id.blank?
    end

    def sms_api_url
      ENV["SMS_API_URL"]
    end

    def sms_api_key
      ENV["SMS_API_KEY"]
    end

    def sms_sender_id
      ENV["SMS_SENDER_ID"]
    end
  end
end
