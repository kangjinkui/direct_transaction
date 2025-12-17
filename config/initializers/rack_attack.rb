class Rack::Attack
  # Allow health checks and assets
  safelist("healthcheck") { |req| req.path == "/health" || req.path == "/up" || req.path.start_with?("/assets/") }

  # Throttle: 100 requests per IP per 5 minutes
  throttle("req/ip", limit: 100, period: 5.minutes) do |req|
    req.ip
  end

  # Throttle login attempts to slow brute force
  throttle("logins/ip", limit: 20, period: 5.minutes) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  self.throttled_responder = lambda do |request|
    now = Time.now
    match_data = request.env["rack.attack.match_data"] || {}
    retry_after = match_data[:period]
    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    }
    body = { error: "rate_limited", retry_after: retry_after, timestamp: now.to_i }.to_json
    [429, headers, [body]]
  end
end
