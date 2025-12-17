require "sidekiq"

class PaymentTimeoutWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 1

  def perform
    now = Time.current
    Order.where(status: :payment_pending).where("timeout_at <= ?", now).find_each do |order|
      next if order.cancelled? || order.completed?

      Order.transaction do
        order.cancel_order!
        order.update!(cancelled_at: now)
      end
    end
  end
end
