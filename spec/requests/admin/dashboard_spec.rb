require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin) { create(:user, :admin, last_otp_verified_at: Time.current) }
  let(:user) { create(:user) }

  describe "GET /admin/dashboard" do
    it "requires admin role" do
      sign_in user, scope: :user

      headers = default_html_headers
      get admin_dashboard_path, headers: headers, as: :html

      expect(response).to have_http_status(:forbidden)
    end

    it "renders dashboard data for admins" do
      sign_in admin, scope: :user
      farmer = create(:farmer)
      order = create(:order, farmer:, status: :farmer_review, timeout_at: 30.minutes.from_now)
      create(:order, farmer:, status: :payment_pending)

      headers = default_html_headers
      get admin_dashboard_path, headers: headers, as: :html

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Admin Dashboard")
      expect(response.body).to include(order.order_number)
    end
  end

  def default_html_headers
    {
      "Accept" => "text/html",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15"
    }
  end
end
