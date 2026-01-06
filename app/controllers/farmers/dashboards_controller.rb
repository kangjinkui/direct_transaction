module Farmers
  class DashboardsController < BaseController
    def show
      @farmer = current_farmer

      # 오늘 날짜 범위
      today = Time.current.beginning_of_day..Time.current.end_of_day

      # 주문 통계
      @orders = @farmer.orders.includes(:user, :order_items, :payment)
      @pending_orders = @farmer.orders.where(status: [:pending, :farmer_review]).order(created_at: :desc)
      @recent_orders = @farmer.orders.order(created_at: :desc).limit(10)

      @stats = {
        total_products: @farmer.products.count,
        available_products: @farmer.products.where(is_available: true).count,
        orders_today: @farmer.orders.where(created_at: today).count,
        pending_orders: @pending_orders.count,
        confirmed_orders: @farmer.orders.where(status: :confirmed).count,
        completed_orders: @farmer.orders.where(status: :completed).count,
        total_revenue: @farmer.orders.where(status: :completed).sum(:total_amount)
      }
    end
  end
end
