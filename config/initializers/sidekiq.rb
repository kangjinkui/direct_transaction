if defined?(Sidekiq)
  redis_url = ENV["REDIS_URL"]

  Sidekiq.configure_server do |config|
    config.redis = { url: redis_url } if redis_url.present?

    schedule_file = Rails.root.join("config/sidekiq.yml")
    if File.exist?(schedule_file)
      schedule = YAML.load_file(schedule_file)
      if defined?(Sidekiq::Cron) && schedule["schedule"].present?
        Sidekiq::Cron::Job.load_from_hash(schedule["schedule"])
      end
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: redis_url } if redis_url.present?
  end
end
