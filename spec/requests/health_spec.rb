require "rails_helper"
require "sidekiq/api"

RSpec.describe "Health", type: :request do
  describe "GET /health" do
    it "returns ok when db and redis are healthy" do
      allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
      fake_redis = double(ping: "PONG")
      allow(Sidekiq).to receive(:redis).and_yield(fake_redis)
      allow(Sidekiq::Queue).to receive(:new).and_call_original
      allow_any_instance_of(Sidekiq::Queue).to receive(:size).and_return(0)

      get "/health"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
      expect(json["db"]).to eq("ok")
      expect(json["redis"]).to eq("ok")
      expect(json["sidekiq_queues"]).to include("critical", "default")
    end

    it "returns service_unavailable when redis fails" do
      allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
      allow(Sidekiq).to receive(:redis).and_raise(StandardError.new("redis down"))

      get "/health"

      expect(response).to have_http_status(:service_unavailable)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("degraded")
      expect(json["redis"]).to eq("error")
    end
  end
end
