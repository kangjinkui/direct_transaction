module Farmers
  class OrdersController < BaseController
    before_action :set_order, only: [:show, :approve, :reject]

    def index
      @orders = current_farmer.orders
                              .includes(:user, :order_items, :payment)
                              .order(created_at: :desc)

      # 필터링
      if params[:status].present?
        @orders = @orders.where(status: params[:status])
      end

      @stats = {
        total: current_farmer.orders.count,
        pending: current_farmer.orders.where(status: [:pending, :farmer_review]).count,
        confirmed: current_farmer.orders.where(status: :confirmed).count,
        payment_pending: current_farmer.orders.where(status: :payment_pending).count,
        completed: current_farmer.orders.where(status: :completed).count
      }
    end

    def show
      @order = current_farmer.orders
                            .includes(:user, :order_items, :payment)
                            .find(params[:id])
    end

    def approve
      result = OrderApprovalService.new(@order).approve(actor: current_user)

      if result.status == :approved
        redirect_to farmers_order_path(@order), notice: "주문을 승인했습니다."
      else
        redirect_to farmers_order_path(@order), alert: "승인할 수 없습니다: #{result.message}"
      end
    end

    def reject
      @order.rejection_reason = params[:rejection_reason].to_s.strip.presence

      result = OrderApprovalService.new(@order).reject(actor: current_user)
      @order.save if @order.changed?

      if result.status == :rejected
        redirect_to farmers_order_path(@order), notice: "주문을 거절했습니다."
      else
        redirect_to farmers_order_path(@order), alert: "거절할 수 없습니다: #{result.message}"
      end
    end

    private

    def set_order
      @order = current_farmer.orders.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to farmers_orders_path, alert: "주문을 찾을 수 없습니다."
    end
  end
end
