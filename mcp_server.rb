#!/usr/bin/env ruby

require "json"
require "logger"
require_relative "config/environment"

class PokemonMcpStdio
  def initialize
    @logger = Logger.new($stderr)
    @logger.level = Logger::INFO
    @dispatcher = Mcp::Dispatcher.new
  end

  def start
    @logger.info "Starting Pokémon MCP server (stdio)..."
    $stdin.each_line do |line|
      line = line.strip
      next if line.empty?

      begin
        request = JSON.parse(line)
        response = Rails.logger.tagged("mcp") { @dispatcher.handle(request) }
        next if response.nil? # notification
        $stdout.puts JSON.generate(response)
        $stdout.flush
      rescue JSON::ParserError => e
        @logger.error "Invalid JSON: #{e.message}"
        $stdout.puts JSON.generate(
          jsonrpc: "2.0",
          id: nil,
          error: { code: Mcp::Dispatcher::JSONRPC_PARSE_ERROR, message: "Parse error: #{e.message}" }
        )
        $stdout.flush
      rescue => e
        @logger.error "Error: #{e.class}: #{e.message}"
        $stdout.puts JSON.generate(
          jsonrpc: "2.0",
          id: nil,
          error: { code: Mcp::Dispatcher::JSONRPC_INTERNAL_ERROR, message: e.message }
        )
        $stdout.flush
      end
    end
  end
end

if __FILE__ == $0
  PokemonMcpStdio.new.start
end
