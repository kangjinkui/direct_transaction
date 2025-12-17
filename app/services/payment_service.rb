class PaymentService
  Result = Struct.new(:status, :order, :payment, :error, keyword_init: true)

  def initialize(order, actor: nil)
    @order = order
    @actor = actor
  end

  # 기록된 입금 내역을 pending 상태로 저장하고 주문을 payment_pending으로 전이
  def report_transfer(amount:, reference: nil, admin_note: nil)
    Order.transaction do
      order.status_changed_by = actor if actor
      order.await_payment! if order.may_await_payment?
      payment = upsert_payment!(
        amount:,
        reference:,
        admin_note:,
        status: :pending,
        payment_method: :manual_transfer
      )
      Result.new(status: :payment_pending, order:, payment:)
    end
  rescue AASM::InvalidTransition => e
    Result.new(status: :invalid_transition, order:, error: e.message)
  end

  # 관리자가 입금 확인을 완료하고 주문을 completed로 전이
  def verify!(verified_at: Time.current, admin_note: nil)
    Order.transaction do
      order.status_changed_by = actor if actor
      order.await_payment! if order.may_await_payment?
      return Result.new(status: :invalid_transition, order:, error: :cannot_complete) unless order.may_complete_order?

      payment = upsert_payment!(
        status: :verified,
        verified_at:,
        admin_note:
      )
      order.complete_order!
      Result.new(status: :completed, order:, payment:)
    end
  rescue AASM::InvalidTransition => e
    Result.new(status: :invalid_transition, order:, error: e.message)
  end

  private

  attr_reader :order, :actor

  def upsert_payment!(attributes)
    payment = order.payment || order.build_payment
    payment.assign_attributes(attributes)
    payment.save!
    payment
  end
end
