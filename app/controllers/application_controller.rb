class ApplicationController < ActionController::Base
  include Pundit::Authorization

  add_flash_types :info, :error, :success

  before_action :authenticate_user!
  before_action :require_admin_otp!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :log_request_metadata

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  rescue_from Pundit::NotAuthorizedError do
    redirect_to(request.referer || root_path, alert: "접근 권한이 없습니다.")
  end

  protected

  def require_admin_otp!
    return unless admin_otp_required?

    redirect_to new_admin_otp_path, alert: "관리자 OTP 재인증이 필요합니다."
  end

  def admin_otp_required?
    user_signed_in? &&
      current_user.needs_admin_otp? &&
      !devise_controller? &&
      controller_path != "admin_otps"
  end

  def require_admin!
    return if current_user&.admin_like?

    respond_to do |format|
      format.html { head :forbidden }
      format.json { head :forbidden }
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name phone address role])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name phone address role])
  end

  private

  def log_request_metadata
    request.env["request_start_time"] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
