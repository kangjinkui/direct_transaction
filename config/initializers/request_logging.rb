class RequestLoggingMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    start = env["request_start_time"] || Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, response = @app.call(env)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(2)

    path = env["PATH_INFO"].to_s
    unless skip_path?(path)
      Rails.logger.info({
        event: "request",
        method: env["REQUEST_METHOD"],
        path: path,
        status: status,
        duration_ms: duration_ms,
        user_id: env["warden"]&.user&.id,
        ip: env["REMOTE_ADDR"]
      }.to_json)
    end

    [status, headers, response]
  end

  private

  def skip_path?(path)
    path.start_with?("/assets", "/favicon", "/health", "/up")
  end
end

Rails.application.config.middleware.insert_before Rack::Runtime, RequestLoggingMiddleware
