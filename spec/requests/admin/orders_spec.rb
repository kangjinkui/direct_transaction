require "rails_helper"

RSpec.describe "Admin::Orders", type: :request do
  let(:admin) { create(:user, :admin, last_otp_verified_at: Time.current) }
  let(:user) { create(:user) }

  describe "GET /admin/orders" do
    it "lists farmer_review orders by default for admin" do
      order = create(:order, status: :farmer_review)
      sign_in admin, scope: :user

      get admin_orders_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.order_number)
    end

    it "lists payment_pending orders when scoped" do
      order = create(:order, status: :payment_pending)
      sign_in admin, scope: :user

      get admin_orders_path(scope: :payment_pending)

      expect(response.body).to include(order.order_number)
    end

    it "filters imminent when requested" do
      timed_out = create(:order, status: :farmer_review, timeout_at: 1.hour.ago)
      far_future = create(:order, status: :farmer_review, timeout_at: 3.hours.from_now)
      sign_in admin, scope: :user

      get admin_orders_path(imminent: true)

      expect(response.body).to include(timed_out.order_number)
      expect(response.body).not_to include(far_future.order_number)
    end

    it "returns json with stats" do
      order = create(:order, status: :payment_pending)
      sign_in admin, scope: :user

      get admin_orders_path(scope: :payment_pending, format: :json)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["stats"]["payment_pending"]).to be >= 1
      expect(json["summary"]).to include("orders_today", "amount_today")
      expect(json["data"].first["order_number"]).to eq(order.order_number)
    end

    it "rejects non-admin" do
      sign_in user, scope: :user

      get admin_orders_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /admin/orders/:id/confirm" do
    it "allows admin to confirm farmer_review order and deducts stock" do
      product = create(:product, stock_quantity: 5)
      order = create(:order, status: :farmer_review)
      create(:order_item, order:, product:, quantity: 2, price: 1000)
      sign_in admin, scope: :user

      post confirm_admin_order_path(order)

      expect(response).to redirect_to(admin_orders_path(scope: "farmer_review"))
      expect(order.reload.status).to eq("confirmed")
      expect(product.reload.stock_quantity).to eq(3)
    end

    it "notifies user on confirm" do
      product = create(:product, stock_quantity: 5)
      user_with_phone = create(:user, phone: "+821011112222")
      order = create(:order, status: :farmer_review, user: user_with_phone)
      create(:order_item, order:, product:, quantity: 1, price: 1000)
      sign_in admin, scope: :user

      expect do
        post confirm_admin_order_path(order)
      end.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.notification_type).to eq("order_status")
      expect(notification.status).to eq("sent")
      expect(notification.channel).to eq("kakao")
      expect(notification.order_id).to eq(order.id)
    end
  end

  describe "POST /admin/orders/:id/cancel" do
    it "allows admin to cancel farmer_review order" do
      order = create(:order, status: :farmer_review)
      sign_in admin, scope: :user

      post cancel_admin_order_path(order)

      expect(response).to redirect_to(admin_orders_path(scope: "farmer_review"))
      expect(order.reload.status).to eq("cancelled")
    end

    it "notifies user on cancel" do
      order = create(:order, status: :farmer_review, user: create(:user, phone: "+821033344455"))
      sign_in admin, scope: :user

      expect do
        post cancel_admin_order_path(order)
      end.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.notification_type).to eq("order_status")
      expect(notification.status).to eq("sent")
      expect(notification.order_id).to eq(order.id)
    end

    it "forbids non-admin" do
      order = create(:order, status: :farmer_review)
      sign_in user, scope: :user

      post cancel_admin_order_path(order)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
