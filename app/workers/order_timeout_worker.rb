require "sidekiq"

class OrderTimeoutWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 1

  def perform
    now = Time.current
    Order.where(status: %i[pending farmer_review]).where("timeout_at <= ?", now).find_each do |order|
      next if order.cancelled?

      Order.transaction do
        order.cancel_order!
        order.update!(cancelled_at: now)
      end
    end
  end
end
