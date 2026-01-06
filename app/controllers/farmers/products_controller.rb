module Farmers
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = current_farmer.products.order(created_at: :desc)
    end

    def show
    end

    def new
      @product = current_farmer.products.build
    end

    def create
      @product = current_farmer.products.build(product_params)

      if @product.save
        redirect_to farmers_products_path, notice: "상품이 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to farmers_products_path, notice: "상품이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to farmers_products_path, notice: "상품이 삭제되었습니다."
    end

    private

    def set_product
      @product = current_farmer.products.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to farmers_products_path, alert: "상품을 찾을 수 없습니다."
    end

    def product_params
      params.require(:product).permit(
        :name,
        :description,
        :price,
        :stock_quantity,
        :stock_status,
        :is_available,
        :image_url
      )
    end
  end
end
