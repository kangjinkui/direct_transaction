class ProductsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @farmer = Farmer.find(params[:farmer_id]) if params[:farmer_id]
    @products = if @farmer
                  @farmer.products.available.order(created_at: :desc)
                else
                  Product.available.includes(:farmer).order(created_at: :desc)
                end
  end

  def show
    @product = Product.find(params[:id])
    @farmer = @product.farmer
  end
end
