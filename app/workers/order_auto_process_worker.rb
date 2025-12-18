class OrderAutoProcessWorker
  include Sidekiq::Worker

  sidekiq_options queue: :critical, retry: 1

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless processable_order?(order)

    result = OrderApprovalService.new(order).auto_process!
    handle_insufficient_stock(order) if result.status == :rejected_insufficient_stock
  rescue StandardError => e
    Rails.logger.error("[OrderAutoProcessWorker] order_id=#{order_id} failed: #{e.message}")
    raise
  end

  private

  def processable_order?(order)
    return false if order.nil?
    return false unless order.farmer&.approval_mode == "auto"
    order.pending?
  end

  def handle_insufficient_stock(order)
    product_names = depleted_product_names(order)
    return if product_names.empty?

    message = "#{product_names.join(', ')} 재고가 부족하여 주문 #{order.order_number}을 처리할 수 없습니다. 재고를 보충해주세요."
    dispatcher.send!(
      order: order,
      farmer: order.farmer,
      notification_type: "stock_depleted",
      channel: order.farmer.notification_method || "kakao",
      metadata: {
        message: message,
        variables: {
          order_number: order.order_number,
          products: product_names
        }
      }
    )
  rescue StandardError => e
    Rails.logger.warn("[OrderAutoProcessWorker] stock alert failed for order #{order.id}: #{e.message}")
  end

  def depleted_product_names(order)
    order.order_items.includes(:product).select do |item|
      product = item.product
      product.present? && product.stock_quantity < item.quantity
    end.map { |item| item.product.name }.uniq
  end

  def dispatcher
    @dispatcher ||= NotificationDispatcher.new(
      primary: NotificationProviders::Kakao.new,
      fallback: NotificationProviders::Sms.new
    )
  end
end
