require "rails_helper"

RSpec.describe "Admin::Payments", type: :request do
  let(:admin) { create(:user, :admin, last_otp_verified_at: Time.current) }
  let(:user) { create(:user) }
  let(:order) { create(:order, status: :payment_pending) }
  let(:payment) { create(:payment, order:, status: :pending, amount: 30_000) }

  describe "POST /admin/payments/:id/verify" do
    it "requires sign in" do
      post verify_admin_payment_path(payment)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "verifies payment and completes order as admin" do
      sign_in admin, scope: :user

      post verify_admin_payment_path(payment), params: { payment: { admin_note: "입금 확인", verification_method: :phone_call } }

      expect(response).to redirect_to(admin_payments_path)
      expect(payment.reload.status).to eq("verified")
      expect(payment.admin_note).to eq("입금 확인")
      expect(payment.verification_method).to eq("phone_call")
      expect(order.reload.status).to eq("completed")
    end

    it "rejects verification without method" do
      sign_in admin, scope: :user

      post verify_admin_payment_path(payment), params: { payment: { admin_note: "입금 확인" } }

      expect(response).to redirect_to(admin_payments_path)
      expect(flash[:alert]).to be_present
      expect(payment.reload).to be_pending
    end

    it "rejects non-admins" do
      sign_in user, scope: :user

      post verify_admin_payment_path(payment), params: { payment: { admin_note: "입금 확인", verification_method: :phone_call } }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /admin/payments" do
    it "renders pending payments for admin" do
      payment
      sign_in admin, scope: :user

      get admin_payments_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(payment.order.order_number)
    end

    it "forbids non-admin" do
      sign_in user, scope: :user

      get admin_payments_path

      expect(response).to have_http_status(:forbidden)
    end
  end
end
