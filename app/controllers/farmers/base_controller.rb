module Farmers
  class BaseController < ApplicationController
    before_action :require_farmer!
    before_action :ensure_farmer_profile

    layout "farmers"

    private

    def ensure_farmer_profile
      return if current_farmer

      redirect_to root_path, alert: "농가 프로필이 설정되지 않았습니다. 관리자에게 문의하세요."
    end
  end
end
