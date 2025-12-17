require 'rails_helper'

RSpec.describe "home/index.html.tailwindcss", type: :view do
  it "shows login prompt when signed out" do
    allow(view).to receive(:user_signed_in?).and_return(false)

    render template: "home/index"

    expect(rendered).to include("강남 직거래마켓 홈")
    expect(rendered).to include("로그인")
  end

  it "greets current user when signed in" do
    allow(view).to receive(:user_signed_in?).and_return(true)
    current_user = build_stubbed(:user, name: "Admin")
    allow(view).to receive(:current_user).and_return(current_user)

    render template: "home/index"

    expect(rendered).to include("어서 오세요")
    expect(rendered).to include("Admin")
  end
end
