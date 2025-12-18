module Admin
  class DashboardsController < ApplicationController
    before_action :require_admin!

    def show
      now = Time.current
      imminent_cutoff = now + 2.hours

      @farmer_review_orders = Order
                                .includes(:farmer, :user)
                                .where(status: :farmer_review)
                                .where("timeout_at IS NULL OR timeout_at <= ?", imminent_cutoff)
                                .order(Arel.sql("timeout_at IS NULL"), :timeout_at)

      @payment_pending_orders = Order
                                  .includes(:farmer, :user, :payment)
                                  .where(status: :payment_pending)
                                  .order(:created_at)

      today_range = now.beginning_of_day..now.end_of_day
      todays_orders = Order.where(created_at: today_range)

      @stats = {
        orders_today: todays_orders.count,
        amount_today: todays_orders.sum(:total_amount),
        completed_today: todays_orders.where(status: :completed).count,
        farmer_review_count: @farmer_review_orders.count,
        payment_pending_count: @payment_pending_orders.count
      }

      respond_to do |format|
        format.html
        format.turbo_stream { render :show, formats: :html }
      end
    end
  end
end
