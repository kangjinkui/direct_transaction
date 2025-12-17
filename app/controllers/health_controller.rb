class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_action :require_admin_otp!

  def show
    db_ok = database_ok?
    redis_ok = redis_ok?
    queues = sidekiq_queue_sizes

    status_code = (db_ok && redis_ok) ? :ok : :service_unavailable
    render json: {
      status: status_code == :ok ? "ok" : "degraded",
      db: db_ok ? "ok" : "error",
      redis: redis_ok ? "ok" : "error",
      sidekiq_queues: queues
    }, status: status_code
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.active?
  rescue StandardError => e
    Rails.logger.warn("[health] db check failed: #{e.class} #{e.message}")
    false
  end

  def redis_ok?
    Sidekiq.redis { |conn| conn.ping == "PONG" }
  rescue StandardError => e
    Rails.logger.warn("[health] redis check failed: #{e.class} #{e.message}")
    false
  end

  def sidekiq_queue_sizes
    %w[critical default].index_with do |queue_name|
      Sidekiq::Queue.new(queue_name).size
    end
  rescue StandardError => e
    Rails.logger.warn("[health] sidekiq queue check failed: #{e.class} #{e.message}")
    {}
  end
end
