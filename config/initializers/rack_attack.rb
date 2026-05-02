class Rack::Attack
  # Use a per-process memory store so rate limiting doesn't depend on
  # Rails.cache (Solid Cache requires a separate DB that may not exist
  # on every deploy). Counters reset on restart and aren't shared across
  # workers/instances — fine for a single-instance Railway deploy.
  self.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Throttle MCP requests by bearer token: 60 req/min per token.
  # Unauthenticated requests skip this throttle (they 401 in the controller).
  throttle("mcp/req per token", limit: 60, period: 60) do |req|
    if req.path == "/mcp"
      header = req.get_header("HTTP_AUTHORIZATION").to_s
      token  = header.split(" ", 2).last
      # Hash to keep raw tokens out of cache keys / logs.
      Digest::SHA256.hexdigest(token) if token.present?
    end
  end

  self.throttled_responder = lambda do |req|
    match  = req.env["rack.attack.match_data"] || {}
    period = match[:period].to_i
    retry_after = period > 0 ? (period - (Time.now.to_i % period)).to_s : "60"

    body = {
      jsonrpc: "2.0",
      id: nil,
      error: { code: -32000, message: "Rate limit exceeded. Try again in #{retry_after}s." }
    }.to_json

    [
      429,
      { "content-type" => "application/json", "retry-after" => retry_after },
      [ body ]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack
