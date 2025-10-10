#!/usr/bin/env ruby

require 'json'
require 'open3'

class ReleasePokemonTester
  def initialize
    @server_path = File.join(__dir__, 'mcp_server.rb')
  end

  def test_release_workflow
    puts "Testing Pokémon Release Workflow..."

    test_cases = [
      {
        name: "Initialize Server",
        message: {
          jsonrpc: "2.0",
          id: 1,
          method: "initialize",
          params: {}
        }
      },
      {
        name: "Get Ash's Collection (Before)",
        message: {
          jsonrpc: "2.0",
          id: 2,
          method: "tools/call",
          params: {
            name: "get_user_collection",
            arguments: { user_email: "ash.ketchum@pokemon.com" }
          }
        }
      },
      {
        name: "Try to Catch a Pokémon",
        message: {
          jsonrpc: "2.0",
          id: 3,
          method: "tools/call",
          params: {
            name: "attempt_catch_pokemon",
            arguments: {
              pokemon_id: "25",  # Pikachu
              user_email: "ash.ketchum@pokemon.com"
            }
          }
        }
      },
      {
        name: "Get Ash's Collection (After Catch)",
        message: {
          jsonrpc: "2.0",
          id: 4,
          method: "tools/call",
          params: {
            name: "get_user_collection",
            arguments: { user_email: "ash.ketchum@pokemon.com" }
          }
        }
      }
    ]

    Open3.popen3("ruby", @server_path) do |stdin, stdout, stderr, wait_thr|
      caught_pokemon_id = nil

      test_cases.each do |test_case|
        puts "\n--- #{test_case[:name]} ---"

        request_json = JSON.generate(test_case[:message])
        stdin.puts(request_json)
        stdin.flush

        begin
          response_line = stdout.gets
          if response_line
            response = JSON.parse(response_line.strip)

            # Extract caught Pokémon ID for release test
            if test_case[:name] == "Get Ash's Collection (After Catch)" && response.dig('result', 'content', 0, 'text')
              collection_data = JSON.parse(response['result']['content'][0]['text'])
              if collection_data['success'] && collection_data['collection'].any?
                caught_pokemon_id = collection_data['collection'].first['id']
                puts "Found Pokémon to release: ID #{caught_pokemon_id}"
              end
            end

            puts "✅ #{test_case[:name]} completed"
          end
        rescue => e
          puts "❌ Error: #{e.message}"
        end

        sleep 0.5
      end

      # Now test the release functionality
      if caught_pokemon_id
        puts "\n--- Testing Release Pokémon ---"

        release_message = {
          jsonrpc: "2.0",
          id: 5,
          method: "tools/call",
          params: {
            name: "release_pokemon",
            arguments: {
              user_email: "ash.ketchum@pokemon.com",
              pokemon_id: caught_pokemon_id
            }
          }
        }

        request_json = JSON.generate(release_message)
        puts "Releasing Pokémon ID: #{caught_pokemon_id}"
        stdin.puts(request_json)
        stdin.flush

        begin
          response_line = stdout.gets
          if response_line
            response = JSON.parse(response_line.strip)
            if response.dig('result', 'content', 0, 'text')
              release_result = JSON.parse(response['result']['content'][0]['text'])

              if release_result['success']
                puts "✅ Successfully released: #{release_result['message']}"
                puts "   Remaining Pokémon: #{release_result['remaining_count']}"
              else
                puts "❌ Release failed: #{release_result['error']}"
              end
            end
          end
        rescue => e
          puts "❌ Release test error: #{e.message}"
        end

        # Verify collection after release
        puts "\n--- Get Collection (After Release) ---"
        final_check = {
          jsonrpc: "2.0",
          id: 6,
          method: "tools/call",
          params: {
            name: "get_user_collection",
            arguments: { user_email: "ash.ketchum@pokemon.com" }
          }
        }

        stdin.puts(JSON.generate(final_check))
        stdin.flush

        begin
          response_line = stdout.gets
          if response_line
            response = JSON.parse(response_line.strip)
            if response.dig('result', 'content', 0, 'text')
              final_collection = JSON.parse(response['result']['content'][0]['text'])
              puts "✅ Final collection count: #{final_collection['count']}"
            end
          end
        rescue => e
          puts "❌ Final check error: #{e.message}"
        end
      else
        puts "\n❌ No Pokémon found to test release functionality"
      end

      stdin.close
      wait_thr.value
    end
  end
end

if __FILE__ == $0
  require 'timeout'

  tester = ReleasePokemonTester.new
  tester.test_release_workflow
end
