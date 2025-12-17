class DailySummaryService
  SUMMARY_STATUSES = %w[confirmed payment_pending completed].freeze

  def initialize(date: Date.current)
    @date = date
  end

  def deliver!
    Farmer.where(approval_mode: :auto).find_each do |farmer|
      deliver_for_farmer(farmer)
    end
  end

  private

  attr_reader :date

  def deliver_for_farmer(farmer)
    orders = farmer.orders.where(status: SUMMARY_STATUSES).where(created_at: date.beginning_of_day..date.end_of_day)
    return if orders.empty?

    count = orders.count
    amount = orders.sum(:total_amount)
    message = "오늘 주문 #{count}건, 총 #{amount}원"

    dispatcher.send!(
      order: nil,
      farmer: farmer,
      notification_type: "daily_summary",
      channel: "sms",
      metadata: { message: }
    )
  end

  def dispatcher
    @dispatcher ||= NotificationDispatcher.new(primary: NotificationProviders::Sms.new)
  end
end
