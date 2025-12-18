require "rails_helper"

RSpec.describe "Admin::Farmers", type: :request do
  let(:admin) { create(:user, :admin, last_otp_verified_at: Time.current) }
  let(:user) { create(:user) }
  let(:farmer) { create(:farmer, account_info: "국민은행 123-456-789012 홍길동") }

  describe "GET /admin/farmers" do
    it "blocks non admin users" do
      sign_in user, scope: :user

      get admin_farmers_path

      expect(response).to have_http_status(:forbidden)
    end

    it "renders list for admins" do
      sign_in admin, scope: :user

      get admin_farmers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("농가 관리")
    end
  end

  describe "POST /admin/farmers" do
    it "creates a farmer" do
      sign_in admin, scope: :user

      expect do
        post admin_farmers_path,
             params: {
               farmer: {
                 business_name: "새농가",
                 owner_name: "홍길동",
                 phone: "+821011112222",
                 account_info: "농협 123-456-789012 홍길동",
                 stock_quantity: 5
               }
             }
      end.to change(Farmer, :count).by(1)
      expect(response).to redirect_to(admin_farmer_path(Farmer.last))
    end
  end

  describe "PATCH /admin/farmers/:id" do
    it "updates existing farmer" do
      sign_in admin, scope: :user

      patch admin_farmer_path(farmer),
            params: { farmer: { business_name: "수정농가" } }

      expect(response).to redirect_to(admin_farmer_path(farmer))
      expect(farmer.reload.business_name).to eq("수정농가")
    end
  end

  describe "DELETE /admin/farmers/:id" do
    it "removes farmer" do
      sign_in admin, scope: :user
      target = create(:farmer)

      expect do
        delete admin_farmer_path(target)
      end.to change(Farmer, :count).by(-1)
      expect(response).to redirect_to(admin_farmers_path)
    end
    it "blocks deletion when orders exist" do
      sign_in admin, scope: :user
      target = create(:farmer)
      create(:order, farmer: target)

      expect do
        delete admin_farmer_path(target)
      end.not_to change(Farmer, :count)

      expect(response).to redirect_to(admin_farmer_path(target))
      expect(flash[:alert]).to eq("Farmer with existing orders cannot be deleted.")
    end

  end

  describe "GET /admin/farmers/:id/account_info" do
    it "requires admin" do
      sign_in user, scope: :user

      get account_info_admin_farmer_path(farmer)

      expect(response).to have_http_status(:forbidden)
    end

    it "renders full account info for admin" do
      sign_in admin, scope: :user

      get account_info_admin_farmer_path(farmer)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(farmer.account_info)
    end
  end
end
