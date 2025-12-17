require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  it "allows health check without throttling" do
    5.times { get "/health" }
    expect(response).to have_http_status(:ok).or have_http_status(:service_unavailable)
  end

  it "throttles excessive requests by IP" do
    allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return("1.2.3.4")

    100.times { get root_path }
    get root_path

    expect(response.status).to eq(429)
    json = JSON.parse(response.body)
    expect(json["error"]).to eq("rate_limited")
  end
end
