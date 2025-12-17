class OrderApprovalService
  TOKEN_TTL = 30.minutes

  Result = Struct.new(:status, :order, :token, :error, keyword_init: true)

  def initialize(order)
    @order = order
  end

  def generate_token(purpose: "farmer_approval")
    Order.transaction do
      order.submit_for_review! if order.may_submit_for_review?
      token = order.order_approval_tokens.create!(
        token: SecureRandom.hex(16),
        expires_at: TOKEN_TTL.from_now,
        purpose:
      )
      Result.new(status: :generated, order:, token:)
    end
  end

  def approve(token:)
    process_with_token(token) do
      confirm_with_stock!
      :approved
    end
  end

  def reject(token:)
    process_with_token(token) do
      order.reject_order! if order.may_reject_order?
      :rejected
    end
  end

  def auto_process!
    return Result.new(status: :skipped, order:) unless order.farmer.approval_mode == "auto"

    if stock_sufficient?
      confirm_with_stock!
      Result.new(status: :auto_confirmed, order:)
    else
      order.reject_order! if order.may_reject_order?
      Result.new(status: :rejected_insufficient_stock, order:, error: :insufficient_stock)
    end
  end

  private

  attr_reader :order

  def process_with_token(raw_token)
    token = order.order_approval_tokens.active.find_by(token: raw_token)
    return Result.new(status: :invalid_token, order:, error: :invalid_token) unless token

    Order.transaction do
      token.use!
      status = yield
      Result.new(status:, order:)
    end
  rescue AASM::InvalidTransition => e
    Result.new(status: :invalid_transition, order:, error: e.message)
  end

  def confirm_with_stock!
    Order.transaction do
      if stock_sufficient?
        deduct_stock!
        order.submit_for_review! if order.may_submit_for_review?
        order.confirm_order! if order.may_confirm_order?
      else
        raise ActiveRecord::RecordInvalid, "Insufficient stock"
      end
    end
  end

  def stock_sufficient?
    order.order_items.includes(:product).all? do |item|
      item.product.stock_quantity >= item.quantity
    end
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
end
