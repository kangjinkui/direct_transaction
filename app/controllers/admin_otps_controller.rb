class AdminOtpsController < ApplicationController
  skip_before_action :require_admin_otp!

  def new
    @challenge = AdminOtpService.new(current_user).generate.challenge
    flash.now[:info] = "OTP를 발송했습니다."
  end

  def create
    result = AdminOtpService.new(current_user).verify(params[:code].to_s)
    if result.status == :verified
      redirect_to root_path, notice: "OTP 인증이 완료되었습니다."
    else
      flash.now[:alert] = "OTP가 올바르지 않거나 만료되었습니다."
      render :new, status: :unprocessable_entity
    end
  end
end
