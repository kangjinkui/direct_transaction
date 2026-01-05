class BadgeComponent < ViewComponent::Base
  attr_reader :status, :size, :html_options

  STATUS_CONFIG = {
    pending: { color: "badge-warning", text: "주문 대기" },
    farmer_review: { color: "badge-info", text: "농가 검토중" },
    confirmed: { color: "badge-success", text: "주문 확정" },
    payment_pending: { color: "badge-primary", text: "입금 대기" },
    completed: { color: "badge-success", text: "완료" },
    cancelled: { color: "badge-neutral", text: "취소" },
    # Custom badges
    success: { color: "badge-success", text: nil },
    error: { color: "badge-error", text: nil },
    warning: { color: "badge-warning", text: nil },
    info: { color: "badge-info", text: nil }
  }.freeze

  SIZES = {
    sm: "badge-sm",
    md: "",
    lg: "badge-lg"
  }.freeze

  def initialize(status:, size: :md, custom_text: nil, **html_options)
    @status = status.to_sym
    @size = size
    @custom_text = custom_text
    @html_options = html_options
  end

  def css_classes
    classes = ["badge", color_class, SIZES[size]]
    classes << html_options[:class] if html_options[:class]
    classes.compact.join(" ")
  end

  def badge_text
    @custom_text || STATUS_CONFIG.dig(status, :text) || status.to_s
  end

  private

  def color_class
    STATUS_CONFIG.dig(status, :color) || "badge-neutral"
  end
end
