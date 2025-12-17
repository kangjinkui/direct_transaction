module Admin
  class OrdersController < ApplicationController
    before_action :require_admin!
    before_action :set_filters
    before_action :set_order, only: %i[confirm cancel]

    def index
      now = Time.current
      scope_relation = base_scope(@scope)
      scope_relation = scope_relation.where("timeout_at <= ?", now + 2.hours) if @imminent_only
      @orders = scope_relation.order(@sort => :asc).includes(:farmer, :user, :payment)
      @stats = {
        farmer_review: Order.where(status: :farmer_review).count,
        payment_pending: Order.where(status: :payment_pending).count,
        timed_out: Order.where(status: %i[farmer_review payment_pending]).where("timeout_at <= ?", now).count
      }
      @summary = summary_stats(now:)
      @now = now

      respond_to do |format|
        format.html
        format.json do
          render json: {
            stats: @stats,
            summary: @summary,
            data: @orders.map { |order| order_json(order, now:) }
          }
        end
      end
    end

    def confirm
      result = AdminOrderActionService.new(@order).confirm_with_stock!
      respond_to_action(result, success_message: "주문을 확인했습니다.")
    end

    def cancel
      result = AdminOrderActionService.new(@order).cancel!
      respond_to_action(result, success_message: "주문을 취소했습니다.")
    end

    private

    def set_filters
      @scope = params[:scope].presence_in(%w[farmer_review payment_pending]) || "farmer_review"
      @sort = params[:sort].presence_in(%w[timeout_at created_at]) || "timeout_at"
      @imminent_only = ActiveModel::Type::Boolean.new.cast(params[:imminent])
    end

    def base_scope(scope)
      case scope
      when "payment_pending"
        Order.where(status: :payment_pending)
      else
        Order.where(status: :farmer_review)
      end
    end

    def order_json(order, now:)
      timed_out = order.timeout_at && order.timeout_at <= now
      imminent = !timed_out && order.timeout_at && order.timeout_at <= now + 2.hours
      {
        id: order.id,
        order_number: order.order_number,
        status: order.status,
        timeout_at: order.timeout_at,
        farmer: {
          id: order.farmer_id,
          name: order.farmer.business_name
        },
        user: {
          id: order.user_id,
          name: order.user.name
        },
        payment: order.payment&.as_json(only: %i[id status amount reference]),
        timed_out: timed_out,
        imminent: imminent
      }
    end

    def respond_to_action(result, success_message:)
      respond_to do |format|
        if %i[confirmed cancelled].include?(result.status)
          format.html { redirect_to admin_orders_path(scope: @scope), notice: success_message }
          format.json { render json: { status: result.status, order_status: result.order.status }, status: :ok }
        else
          format.html { redirect_to admin_orders_path(scope: @scope), alert: "처리할 수 없습니다: #{result.error}" }
          format.json { render json: { error: result.error, status: result.status }, status: :unprocessable_entity }
        end
      end
    end

    def set_order
      @order = Order.find(params[:id])
    end

    def summary_stats(now:)
      today = now.beginning_of_day..now.end_of_day
      orders_today = Order.where(created_at: today)
      {
        orders_today: orders_today.count,
        amount_today: orders_today.sum(:total_amount),
        completed_today: orders_today.where(status: :completed).count
      }
    end
  end
end
