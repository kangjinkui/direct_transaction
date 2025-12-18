require "rails_helper"

RSpec.describe "Admin::Products", type: :request do
  let(:admin) { create(:user, :admin, last_otp_verified_at: Time.current) }
  let(:user) { create(:user) }
  let(:farmer) { create(:farmer) }
  let(:product) { create(:product, farmer:) }

  describe "GET /admin/products" do
    it "requires admin role" do
      sign_in user, scope: :user

      get admin_products_path

      expect(response).to have_http_status(:forbidden)
    end

    it "shows list to admins" do
      sign_in admin, scope: :user
      product

      get admin_products_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("상품 관리")
    end
  end

  describe "POST /admin/products" do
    it "creates product" do
      sign_in admin, scope: :user

      expect do
        post admin_products_path,
             params: {
               product: {
                 farmer_id: farmer.id,
                 name: "샘플 상품",
                 description: "시험용 상품",
                 price: 12_000,
                 category: "채소",
                 stock_quantity: 10,
                 stock_status: :available,
                 max_per_order: 3,
                 is_available: true
               }
             }
      end.to change(Product, :count).by(1)
      expect(response).to redirect_to(admin_product_path(Product.last))
    end
  end

  describe "PATCH /admin/products/:id/update_stock" do
    it "updates inventory fields" do
      sign_in admin, scope: :user

      patch update_stock_admin_product_path(product),
            params: { product: { stock_quantity: 99, stock_status: :sold_out } }

      expect(response).to redirect_to(admin_products_path)
      expect(product.reload.stock_quantity).to eq(99)
      expect(product.stock_status).to eq("sold_out")
    end
  end

  describe "DELETE /admin/products/:id" do
    it "removes product" do
      sign_in admin, scope: :user
      product

      expect do
        delete admin_product_path(product)
      end.to change(Product, :count).by(-1)
      expect(response).to redirect_to(admin_products_path)
    end
  end
end
