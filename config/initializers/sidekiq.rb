if defined?(Sidekiq)
  Sidekiq.configure_server do |config|
    schedule_file = Rails.root.join("config/sidekiq.yml")
    if File.exist?(schedule_file)
      schedule = YAML.load_file(schedule_file)
      if defined?(Sidekiq::Cron) && schedule["schedule"].present?
        Sidekiq::Cron::Job.load_from_hash(schedule["schedule"])
      end
    end
  end
end
