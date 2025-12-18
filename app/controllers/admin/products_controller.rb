module Admin
  class ProductsController < ApplicationController
    before_action :require_admin!
    before_action :set_product, only: %i[show edit update destroy update_stock]
    before_action :load_farmer_options, only: %i[new create edit update]

    def index
      @products = Product.order(created_at: :desc).includes(:farmer)
    end

    def show; end

    def new
      @product = Product.new
    end

    def edit; end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_product_path(@product), notice: "상품이 생성되었습니다."
      else
        load_farmer_options
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: "상품 정보를 업데이트했습니다."
      else
        load_farmer_options
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: "상품을 삭제했습니다."
    end

    def update_stock
      if @product.update(stock_params)
        redirect_to admin_products_path, notice: "재고를 수정했습니다."
      else
        redirect_to admin_products_path, alert: @product.errors.full_messages.to_sentence
      end
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :farmer_id,
        :name,
        :description,
        :price,
        :category,
        :stock_quantity,
        :stock_status,
        :max_per_order,
        :is_available,
        :sku
      )
    end

    def stock_params
      params.require(:product).permit(:stock_quantity, :stock_status)
    end

    def load_farmer_options
      @farmer_options = Farmer.order(:business_name).pluck(:business_name, :id)
    end
  end
end
