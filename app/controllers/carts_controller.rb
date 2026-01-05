class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart_items = current_user.cart_items.includes(product: :farmer).order(created_at: :desc)
    @cart_items_by_farmer = @cart_items.group_by { |item| item.product.farmer }
  end

  def create
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    cart_item = current_user.cart_items.find_or_initialize_by(product: product)

    if cart_item.persisted?
      cart_item.quantity += quantity
    else
      cart_item.quantity = quantity
    end

    if cart_item.save
      redirect_to cart_path, notice: "장바구니에 추가되었습니다."
    else
      redirect_to product_path(product), alert: cart_item.errors.full_messages.join(", ")
    end
  end

  def update
    cart_item = current_user.cart_items.find(params[:id])

    if cart_item.update(quantity: params[:quantity])
      redirect_to cart_path, notice: "수량이 변경되었습니다."
    else
      redirect_to cart_path, alert: cart_item.errors.full_messages.join(", ")
    end
  end

  def destroy
    cart_item = current_user.cart_items.find(params[:id])
    cart_item.destroy
    redirect_to cart_path, notice: "상품이 장바구니에서 제거되었습니다."
  end

  def destroy_all
    current_user.cart_items.destroy_all
    redirect_to cart_path, notice: "장바구니가 비워졌습니다."
  end
end
