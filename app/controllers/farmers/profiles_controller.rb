module Farmers
  class ProfilesController < BaseController
    def show
      @farmer = current_farmer
    end

    def edit
      @farmer = current_farmer
    end

    def update
      @farmer = current_farmer

      if @farmer.update(farmer_params)
        redirect_to farmers_profile_path, notice: "프로필이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def farmer_params
      params.require(:farmer).permit(
        :business_name,
        :owner_name,
        :phone,
        :account_info,
        :approval_mode,
        :notification_method
      )
    end
  end
end
