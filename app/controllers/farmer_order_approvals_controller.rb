class FarmerOrderApprovalsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    return render_guard unless load_active_token

    @order = @token.order
                  .includes(:order_items, :user, :farmer)
  end

  def approve
    return render_guard unless load_active_token

    result = OrderApprovalService.new(@token.order).approve(token: @token.token)

    if result.status == :approved
      redirect_to farmer_approval_path(@token.token), notice: "승인이 완료되었습니다."
    else
      redirect_to farmer_approval_path(@token.token), alert: "승인할 수 없습니다."
    end
  end

  def reject
    return render_guard unless load_active_token

    order = @token.order
    order.rejection_reason = params[:rejection_reason].to_s.strip.presence

    result = OrderApprovalService.new(order).reject(token: @token.token)
    order.save if order.changed?

    if result.status == :rejected
      redirect_to farmer_approval_path(@token.token), notice: "주문을 거절했습니다."
    else
      redirect_to farmer_approval_path(@token.token), alert: "거절할 수 없습니다."
    end
  end

  private

  def load_active_token
    @token = OrderApprovalToken.find_by(token: params[:token])
    return false unless @token
    return false if @token.used?
    return false if @token.expired?

    true
  end

  def render_guard
    @guard_title = "링크를 확인할 수 없습니다"
    @guard_message =
      if @token.nil?
        "유효하지 않은 링크입니다."
      elsif @token.used?
        "이미 처리된 링크입니다."
      else
        "링크가 만료되었습니다."
      end

    render :guard, status: :gone
  end
end
