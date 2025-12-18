module Admin
  class FarmersController < ApplicationController
    before_action :require_admin!
    before_action :set_farmer, only: %i[show edit update destroy account_info]

    def index
      @farmers = Farmer.order(created_at: :desc)
    end

    def show; end

    def new
      @farmer = Farmer.new
    end

    def edit; end

    def create
      @farmer = Farmer.new(farmer_params)
      if @farmer.save
        redirect_to admin_farmer_path(@farmer), notice: "농가가 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @farmer.update(farmer_params)
        redirect_to admin_farmer_path(@farmer), notice: "농가 정보를 업데이트했습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @farmer.orders.exists?
        redirect_to admin_farmer_path(@farmer), alert: "Farmer with existing orders cannot be deleted."
      else
        @farmer.destroy
        redirect_to admin_farmers_path, notice: "Farmer was deleted."
      end
    end

    def account_info
      render layout: false
    end

    private

    def set_farmer
      @farmer = Farmer.find(params[:id])
    end

    def farmer_params
      permitted = params.require(:farmer).permit(
        :business_name,
        :owner_name,
        :phone,
        :account_info,
        :farmer_type,
        :notification_method,
        :approval_mode,
        :stock_quantity,
        :pin
      )
      permitted.delete(:pin) if permitted[:pin].blank?
      permitted
    end
  end
end
