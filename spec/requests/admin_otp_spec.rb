require "rails_helper"

RSpec.describe "Admin OTP flow", type: :request do
  let(:admin) { create(:user, role: :admin, last_otp_verified_at: nil) }

  before do
    login_as(admin, scope: :user)
  end

  it "redirects admin needing OTP to OTP page" do
    get root_path
    expect(response).to redirect_to(new_admin_otp_path)
  end

  it "rejects invalid code" do
    get new_admin_otp_path
    post admin_otp_path, params: { code: "000000" }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(admin.reload.last_otp_verified_at).to be_nil
  end

  it "accepts valid code and marks user" do
    get new_admin_otp_path
    challenge = admin.admin_otp_challenges.last

    post admin_otp_path, params: { code: challenge.code }

    expect(response).to redirect_to(root_path)
    expect(admin.reload.last_otp_verified_at).to be_present
    expect(challenge.reload).to be_used
  end
end
