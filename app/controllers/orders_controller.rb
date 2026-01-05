class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show]

  def index
    @orders = current_user.orders.recent.includes(:farmer, :order_items, :payment)
    @orders = @orders.where(status: params[:status]) if params[:status].present?
  end

  def show
    # @order is set by before_action
  end

  def new
    @cart_items = current_user.cart_items.includes(product: :farmer)

    if @cart_items.empty?
      redirect_to cart_path, alert: "장바구니가 비어있습니다."
      return
    end

    @cart_items_by_farmer = @cart_items.group_by { |item| item.product.farmer }
    @order = Order.new
  end

  def create
    cart_items = current_user.cart_items.includes(product: :farmer)

    if cart_items.empty?
      redirect_to cart_path, alert: "장바구니가 비어있습니다."
      return
    end

    # 농가별로 주문 생성
    orders = []
    errors = []

    ActiveRecord::Base.transaction do
      cart_items.group_by { |item| item.product.farmer }.each do |farmer, items|
        order = create_order_for_farmer(farmer, items)

        if order.persisted?
          orders << order
        else
          errors << "#{farmer.name}: #{order.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
        end
      end

      if errors.empty?
        # 주문 성공 시 장바구니 비우기
        current_user.cart_items.destroy_all
      end
    end

    if errors.any?
      @order = Order.new(order_params)
      errors.each { |message| @order.errors.add(:base, message) }
      @cart_items = cart_items
      @cart_items_by_farmer = cart_items.group_by { |item| item.product.farmer }
      render :new, status: :unprocessable_entity
    else
      redirect_to complete_orders_path(order_ids: orders.map(&:id)),
                  notice: "#{orders.count}개의 주문이 생성되었습니다."
    end
  end

  def complete
    order_ids = Array(params[:order_ids]).map(&:to_i)
    @orders = current_user.orders.where(id: order_ids).includes(:farmer)
    redirect_to orders_path, alert: "주문 정보를 찾을 수 없습니다." if @orders.empty?
  end

  def report_payment
    @order = current_user.orders.find(params[:id])
    unless @order.payment_pending?
      redirect_to order_path(@order), alert: "결제 대기 상태에서만 신고할 수 있습니다."
      return
    end

    result = PaymentService.new(@order, actor: current_user).report_transfer(
      amount: @order.total_amount,
      reference: params[:reference]
    )

    if result.status == :payment_pending
      redirect_to order_path(@order), notice: "입금 완료 신고가 접수되었습니다."
    else
      redirect_to order_path(@order), alert: "입금 완료 신고에 실패했습니다."
    end
  end

  def cancel
    @order = current_user.orders.find(params[:id])
    unless @order.may_cancel_order?
      redirect_to order_path(@order), alert: "취소할 수 없는 주문입니다."
      return
    end

    @order.status_changed_by = current_user
    @order.cancel_order!
    redirect_to order_path(@order), notice: "주문이 취소되었습니다."
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end

  def create_order_for_farmer(farmer, cart_items)
    order = current_user.orders.new(
      farmer: farmer,
      shipping_name: order_params[:shipping_name],
      shipping_phone: order_params[:shipping_phone],
      shipping_address: order_params[:shipping_address],
      shipping_zip_code: order_params[:shipping_zip_code],
      delivery_memo: order_params[:delivery_memo],
      total_amount: 0 # 아래에서 계산
    )

    total = 0

    cart_items.each do |cart_item|
      product = cart_item.product

      # 재고 확인
      if cart_item.quantity > product.stock_quantity
        order.errors.add(:base, "#{product.name}의 재고가 부족합니다.")
        return order
      end

      order_item = order.order_items.build(
        product: product,
        quantity: cart_item.quantity,
        price: product.price
      )

      total += order_item.price * order_item.quantity
    end

    order.total_amount = total
    order.save

    # 주문 성공 시 재고 차감
    if order.persisted?
      cart_items.each do |cart_item|
        cart_item.product.decrement!(:stock_quantity, cart_item.quantity)
      end
    end

    order
  end

  def order_params
    params.require(:order).permit(
      :shipping_name,
      :shipping_phone,
      :shipping_address,
      :shipping_zip_code,
      :delivery_memo
    )
  end
end
