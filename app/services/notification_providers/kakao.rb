require "net/http"
require "uri"
require "json"

module NotificationProviders
  class Kakao
    class MissingConfig < StandardError; end

    def deliver!(order:, farmer:, notification_type:, channel:, metadata: {})
      raise "kakao_failed" if metadata[:force_kakao_fail]
      return true if Rails.env.test? && !metadata[:force_network]

      to = metadata[:recipient_phone].presence || farmer&.phone
      raise MissingConfig, "Kakao recipient missing" if to.blank?

      message = metadata[:message] || default_message(notification_type, order:, metadata:)
      raise MissingConfig, "Kakao message missing" if message.blank?

      ensure_config_present!
      perform_delivery(
        to: to,
        sender_key: kakao_sender_key,
        template_id: kakao_template_id,
        variables: metadata[:variables] || {},
        message:
      )
    end

    private

    def default_message(notification_type, order:, metadata:)
      case notification_type
      when "farmer_approval"
        order_number = order&.order_number || metadata[:order_number]
        "Order #{order_number} needs your approval."
      when "daily_summary"
        metadata[:message]
      else
        metadata[:message] || "Notification: #{notification_type}"
      end
    end

    def perform_delivery(payload)
      uri = URI.parse(kakao_api_url)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "KakaoAK #{kakao_api_key}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      raise "kakao_failed" unless response.is_a?(Net::HTTPSuccess)

      true
    end

    def ensure_config_present!
      raise MissingConfig, "KAKAO_API_URL missing" if kakao_api_url.blank?
      raise MissingConfig, "KAKAO_API_KEY missing" if kakao_api_key.blank?
      raise MissingConfig, "KAKAO_SENDER_KEY missing" if kakao_sender_key.blank?
      raise MissingConfig, "KAKAO_TEMPLATE_ID missing" if kakao_template_id.blank?
    end

    def kakao_api_url
      ENV["KAKAO_API_URL"]
    end

    def kakao_api_key
      ENV["KAKAO_API_KEY"]
    end

    def kakao_sender_key
      ENV["KAKAO_SENDER_KEY"]
    end

    def kakao_template_id
      ENV["KAKAO_TEMPLATE_ID"]
    end
  end
end
