module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def kakao
      handle_auth "kakao"
    end

    def naver
      handle_auth "naver"
    end

    private

    def handle_auth(provider)
      @user = User.from_omniauth(request.env["omniauth.auth"])

      if @user.persisted?
        flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: provider.titleize)
        sign_in_and_redirect @user, event: :authentication
      else
        session["devise.#{provider}_data"] = request.env["omniauth.auth"].except("extra")
        redirect_to new_user_registration_url, alert: "인증에 실패했습니다. 다시 시도해 주세요."
      end
    end
  end
end
