require "csv"

module Admin
  class OrdersController < ApplicationController
    before_action :require_admin!
    before_action :set_filters
    before_action :set_order, only: %i[show confirm cancel update_note]

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
      @summary = summary_stats(now: now)
      @now = now

      respond_to do |format|
        format.html
        format.json do
          render json: {
            stats: @stats,
            summary: @summary,
            data: @orders.map { |order| order_json(order, now: now) }
          }
        end
        format.csv do
          send_data orders_csv(@orders),
                    filename: "orders-#{now.strftime('%Y%m%d')}.csv",
                    type: "text/csv"
        end
      end
    end

    def show
      @order = Order.includes(:farmer, :user, :payment, order_items: :product).find(params[:id])
    end

    def update_note
      note = params.require(:order).fetch(:admin_note, "").strip
      history = @order.admin_note_history || []

      if note != @order.admin_note
        history << {
          note: note,
          previous_note: @order.admin_note,
          updated_at: Time.current,
          updated_by_id: current_user.id
        }
      end

      if @order.update(admin_note: note, admin_note_history: history, admin_note_updated_at: Time.current)
        respond_to do |format|
          format.html { redirect_to admin_order_path(@order), notice: "관리자 메모가 저장되었습니다." }
          format.json { render json: { status: :ok, updated_at: @order.admin_note_updated_at }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_order_path(@order), alert: "관리자 메모 저장에 실패했습니다." }
          format.json { render json: { status: :error, errors: @order.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def confirm
      result = AdminOrderActionService.new(@order, actor: current_user).confirm_with_stock!
      respond_to_action(result, success_message: "주문을 승인했습니다.")
    end

    def cancel
      result = AdminOrderActionService.new(@order, actor: current_user).cancel!
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

    def order_json(order, now: Time.current)
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

    def summary_stats(now: Time.current)
      today = now.beginning_of_day..now.end_of_day
      orders_today = Order.where(created_at: today)
      {
        orders_today: orders_today.count,
        amount_today: orders_today.sum(:total_amount),
        completed_today: orders_today.where(status: :completed).count
      }
    end

    def orders_csv(orders)
      headers = %w[order_number status farmer_name user_name total_amount timeout_at payment_status]
      CSV.generate(headers: true) do |csv|
        csv << headers
        orders.each do |order|
          csv << [
            order.order_number,
            order.status,
            order.farmer&.business_name,
            order.user&.name,
            order.total_amount,
            order.timeout_at,
            order.payment&.status
          ]
        end
      end
    end
  end
end
