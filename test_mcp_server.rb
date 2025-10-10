#!/usr/bin/env ruby

require 'json'
require 'open3'

class McpServerTester
  def initialize
    @server_path = File.join(__dir__, 'mcp_server.rb')
  end

  def test_server
    puts "Testing Pokémon MCP Server..."

    # Test messages
    test_cases = [
      {
        name: "Initialize",
        message: {
          jsonrpc: "2.0",
          id: 1,
          method: "initialize",
          params: {}
        }
      },
      {
        name: "List Tools",
        message: {
          jsonrpc: "2.0",
          id: 2,
          method: "tools/list",
          params: {}
        }
      },
      {
        name: "List Resources",
        message: {
          jsonrpc: "2.0",
          id: 3,
          method: "resources/list",
          params: {}
        }
      },
      {
        name: "Get Random Pokémon",
        message: {
          jsonrpc: "2.0",
          id: 4,
          method: "tools/call",
          params: {
            name: "get_random_pokemon",
            arguments: { max_id: 151 }  # Gen 1 only
          }
        }
      },
      {
        name: "Search Pokémon",
        message: {
          jsonrpc: "2.0",
          id: 5,
          method: "tools/call",
          params: {
            name: "search_pokemon",
            arguments: { query: "pikachu" }
          }
        }
      },
      {
        name: "Get User Collection",
        message: {
          jsonrpc: "2.0",
          id: 6,
          method: "tools/call",
          params: {
            name: "get_user_collection",
            arguments: { user_email: "ash.ketchum@pokemon.com" }
          }
        }
      }
    ]

    Open3.popen3("ruby", @server_path) do |stdin, stdout, stderr, wait_thr|
      test_cases.each do |test_case|
        puts "\n--- Testing: #{test_case[:name]} ---"

        # Send request
        request_json = JSON.generate(test_case[:message])
        puts "Request: #{request_json}"
        stdin.puts(request_json)
        stdin.flush

        # Read response (with timeout)
        begin
          response_line = nil
          Timeout.timeout(10) do
            response_line = stdout.gets
          end

          if response_line
            response = JSON.parse(response_line.strip)
            puts "Response: #{JSON.pretty_generate(response)}"

            # Basic validation
            if response['jsonrpc'] == '2.0' && response['id'] == test_case[:message][:id]
              puts "✅ Valid MCP response"
            else
              puts "❌ Invalid MCP response format"
            end
          else
            puts "❌ No response received"
          end
        rescue Timeout::Error
          puts "❌ Timeout waiting for response"
        rescue JSON::ParserError => e
          puts "❌ Invalid JSON response: #{e.message}"
          puts "Raw response: #{response_line}"
        end

        sleep 0.5  # Brief pause between tests
      end

      # Close stdin to signal end
      stdin.close

      # Wait for process to finish
      exit_status = wait_thr.value
      puts "\n--- Server Exit Status: #{exit_status} ---"

      # Check for any stderr output
      error_output = stderr.read
      if !error_output.empty?
        puts "Server Errors:"
        puts error_output
      end
    end
  end
end

if __FILE__ == $0
  require 'timeout'

  tester = McpServerTester.new
  tester.test_server
end
