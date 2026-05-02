class McpController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :authenticate_mcp!

  # POST /mcp
  def handle
    Rails.logger.tagged("mcp") do
      payload =
        begin
          JSON.parse(request.raw_post)
        rescue JSON::ParserError => e
          render json: parse_error(e.message), status: :ok
          return
        end

      response = Mcp::Dispatcher.new.handle(payload)
      if response.nil?
        head :accepted
      else
        render json: response, status: :ok
      end
    end
  end

  private

  def authenticate_mcp!
    expected = ENV["MCP_BEARER_TOKEN"].to_s
    if expected.empty?
      render json: { error: "MCP server is not configured (set MCP_BEARER_TOKEN)" }, status: :service_unavailable
      return
    end

    presented = request.headers["Authorization"].to_s.split(" ", 2).last.to_s
    unless presented.length == expected.length &&
           ActiveSupport::SecurityUtils.secure_compare(presented, expected)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def parse_error(detail)
    {
      jsonrpc: "2.0",
      id: nil,
      error: { code: Mcp::Dispatcher::JSONRPC_PARSE_ERROR, message: "Parse error: #{detail}" }
    }
  end
end
