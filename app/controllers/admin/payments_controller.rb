module Admin
  class PaymentsController < ApplicationController
    before_action :require_admin!

    def index
      @payments = Payment.includes(:order).where(status: :pending).order(created_at: :desc)
      respond_to do |format|
        format.html
        format.json do
          render json: @payments.map { |payment| payment_json(payment) }
        end
      end
    end

    def verify
      payment = Payment.find(params[:id])
      result = PaymentService.new(payment.order).verify!(
        verified_at: Time.current,
        admin_note: params[:admin_note]
      )

      respond_to do |format|
        if result.status == :completed
          format.html do
            redirect_to admin_payments_path, notice: "입금을 확인했습니다."
          end
          format.json do
            render json: {
              status: result.status,
              order_status: result.order.status,
              payment_status: result.payment.status
            }, status: :ok
          end
        else
          format.html do
            redirect_to admin_payments_path, alert: "처리할 수 없습니다."
          end
          format.json { render json: { error: result.error }, status: :unprocessable_entity }
        end
      end
    end

    private

    def require_admin!
      return if current_user&.admin_like?

      respond_to do |format|
        format.html { head :forbidden }
        format.json { head :forbidden }
      end
    end

    def payment_json(payment)
      {
        id: payment.id,
        amount: payment.amount,
        status: payment.status,
        reference: payment.reference,
        order_number: payment.order.order_number,
        order_status: payment.order.status
      }
    end
  end
end
