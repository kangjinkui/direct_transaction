class AdminOrderActionService
  Result = Struct.new(:status, :order, :error, keyword_init: true)

  def initialize(order)
    @order = order
  end

  def confirm_with_stock!
    Order.transaction do
      ensure_review_state!
      deduct_stock!
      order.confirm_order!
    end
    notify_user!(:confirmed)
    Result.new(status: :confirmed, order:)
  rescue AASM::InvalidTransition => e
    Result.new(status: :invalid_transition, order:, error: e.message)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(status: :invalid_record, order:, error: e.message)
  end

  def cancel!
    Order.transaction do
      return Result.new(status: :invalid_transition, order:, error: :cannot_cancel) unless order.may_cancel_order?

      order.cancel_order!
    end
    notify_user!(:cancelled)
    Result.new(status: :cancelled, order:)
  rescue AASM::InvalidTransition => e
    Result.new(status: :invalid_transition, order:, error: e.message)
  end

  private

  attr_reader :order

  def ensure_review_state!
    order.submit_for_review! if order.may_submit_for_review?
    raise AASM::InvalidTransition unless order.may_confirm_order?
  end

  def deduct_stock!
    order.order_items.includes(:product).each do |item|
      product = item.product
      product.with_lock do
        raise ActiveRecord::RecordInvalid, "Insufficient stock" if product.stock_quantity < item.quantity

        product.update!(stock_quantity: product.stock_quantity - item.quantity)
      end
    end
  end

  def notify_user!(status)
    return if order.user&.phone.blank?

    metadata = {
      recipient_phone: order.user.phone,
      message: "Order #{order.order_number} status: #{status}.",
      variables: {
        order_number: order.order_number,
        status: status
      }
    }

    dispatcher.send!(
      order: order,
      farmer: order.farmer,
      notification_type: "order_status",
      channel: order.farmer.notification_method || "kakao",
      metadata:
    )
  rescue StandardError => e
    Rails.logger.warn("[AdminOrderActionService] notify_user failed for order #{order.id}: #{e.message}")
  end

  def dispatcher
    @dispatcher ||= NotificationDispatcher.new(
      primary: NotificationProviders::Kakao.new,
      fallback: NotificationProviders::Sms.new
    )
  end
end
