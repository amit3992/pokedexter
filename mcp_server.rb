#!/usr/bin/env ruby

require 'json'
require 'socket'
require 'logger'
require_relative 'config/environment'

class PokemonMcpServer
  def initialize
    @logger = Logger.new(STDERR)
    @logger.level = Logger::INFO
  end

  def start
    @logger.info "Starting Pokémon MCP Server..."
    
    # Read from STDIN and write to STDOUT for MCP communication
    STDIN.each_line do |line|
      begin
        request = JSON.parse(line.strip)
        response = handle_request(request)
        puts JSON.generate(response)
        STDOUT.flush
      rescue JSON::ParserError => e
        @logger.error "Invalid JSON: #{e.message}"
        puts JSON.generate(error_response("Invalid JSON"))
        STDOUT.flush
      rescue => e
        @logger.error "Error handling request: #{e.message}"
        puts JSON.generate(error_response(e.message))
        STDOUT.flush
      end
    end
  end

  private

  def handle_request(request)
    method = request['method']
    params = request['params'] || {}
    id = request['id']

    case method
    when 'initialize'
      initialize_response(id)
    when 'tools/list'
      list_tools_response(id)
    when 'tools/call'
      call_tool_response(id, params)
    when 'resources/list'
      list_resources_response(id)
    when 'resources/read'
      read_resource_response(id, params)
    else
      error_response("Unknown method: #{method}", id)
    end
  end

  def initialize_response(id)
    {
      jsonrpc: "2.0",
      id: id,
      result: {
        protocolVersion: "2024-11-05",
        capabilities: {
          tools: {},
          resources: {}
        },
        serverInfo: {
          name: "pokemon-mcp-server",
          version: "1.0.0"
        }
      }
    }
  end

  def list_tools_response(id)
    {
      jsonrpc: "2.0",
      id: id,
      result: {
        tools: [
          {
            name: "search_pokemon",
            description: "Search for a Pokémon by name or ID",
            inputSchema: {
              type: "object",
              properties: {
                query: {
                  type: "string",
                  description: "Pokémon name or ID to search for"
                }
              },
              required: ["query"]
            }
          },
          {
            name: "get_random_pokemon",
            description: "Get a random Pokémon from the PokéAPI",
            inputSchema: {
              type: "object",
              properties: {
                max_id: {
                  type: "integer",
                  description: "Maximum Pokémon ID to include (default: 898)",
                  default: 898
                }
              }
            }
          },
          {
            name: "attempt_catch_pokemon",
            description: "Attempt to catch a Pokémon with probability-based success",
            inputSchema: {
              type: "object",
              properties: {
                pokemon_id: {
                  type: "string",
                  description: "ID or name of the Pokémon to catch"
                },
                user_email: {
                  type: "string",
                  description: "Email of the user attempting to catch"
                }
              },
              required: ["pokemon_id", "user_email"]
            }
          },
          {
            name: "get_user_collection",
            description: "Get a user's collection of caught Pokémon",
            inputSchema: {
              type: "object",
              properties: {
                user_email: {
                  type: "string",
                  description: "Email of the user"
                }
              },
              required: ["user_email"]
            }
          },
          {
            name: "release_pokemon",
            description: "Release a Pokémon from a user's collection",
            inputSchema: {
              type: "object",
              properties: {
                user_email: {
                  type: "string",
                  description: "Email of the user"
                },
                pokemon_id: {
                  type: "integer",
                  description: "Database ID of the caught Pokémon to release"
                }
              },
              required: ["user_email", "pokemon_id"]
            }
          },
          {
            name: "get_pokemon_stats",
            description: "Get detailed statistics for a specific Pokémon",
            inputSchema: {
              type: "object",
              properties: {
                pokemon_id: {
                  type: "string",
                  description: "ID or name of the Pokémon"
                }
              },
              required: ["pokemon_id"]
            }
          }
        ]
      }
    }
  end

  def call_tool_response(id, params)
    tool_name = params['name']
    arguments = params['arguments'] || {}

    result = case tool_name
             when 'search_pokemon'
               search_pokemon(arguments['query'])
             when 'get_random_pokemon'
               get_random_pokemon(arguments['max_id'] || 898)
             when 'attempt_catch_pokemon'
               attempt_catch_pokemon(arguments['pokemon_id'], arguments['user_email'])
             when 'get_user_collection'
               get_user_collection(arguments['user_email'])
             when 'release_pokemon'
               release_pokemon(arguments['user_email'], arguments['pokemon_id'])
             when 'get_pokemon_stats'
               get_pokemon_stats(arguments['pokemon_id'])
             else
               return error_response("Unknown tool: #{tool_name}", id)
             end

    {
      jsonrpc: "2.0",
      id: id,
      result: {
        content: [
          {
            type: "text",
            text: JSON.pretty_generate(result)
          }
        ]
      }
    }
  rescue => e
    error_response("Tool execution failed: #{e.message}", id)
  end

  def list_resources_response(id)
    {
      jsonrpc: "2.0",
      id: id,
      result: {
        resources: [
          {
            uri: "pokemon://collections",
            name: "All User Collections",
            description: "List of all users and their Pokémon collections"
          },
          {
            uri: "pokemon://stats/global",
            name: "Global Statistics",
            description: "Global Pokémon catching statistics"
          }
        ]
      }
    }
  end

  def read_resource_response(id, params)
    uri = params['uri']
    
    result = case uri
             when "pokemon://collections"
               get_all_collections
             when "pokemon://stats/global"
               get_global_stats
             else
               return error_response("Unknown resource: #{uri}", id)
             end

    {
      jsonrpc: "2.0",
      id: id,
      result: {
        contents: [
          {
            uri: uri,
            mimeType: "application/json",
            text: JSON.pretty_generate(result)
          }
        ]
      }
    }
  rescue => e
    error_response("Resource read failed: #{e.message}", id)
  end

  def search_pokemon(query)
    pokemon_data = PokeApi.fetch_pokemon(query)
    {
      success: true,
      pokemon: pokemon_data
    }
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def get_random_pokemon(max_id = 898)
    random_id = PokeApi.random_id(max: max_id)
    pokemon_data = PokeApi.fetch_pokemon(random_id)
    {
      success: true,
      pokemon: pokemon_data,
      random_id: random_id
    }
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def attempt_catch_pokemon(pokemon_id, user_email)
    user = User.find_by(email: user_email)
    return { success: false, error: "User not found" } unless user

    if user.caught_pokemons.count >= 10
      return {
        success: false,
        error: "User already has 10 Pokémon! Release some before catching more.",
        limit_reached: true
      }
    end

    pokemon_data = PokeApi.fetch_pokemon(pokemon_id)
    
    if CatchLogic.success?(pokemon_data[:base_experience])
      caught_pokemon = CaughtPokemon.create!(
        user: user,
        poke_id: pokemon_data[:poke_id],
        name: pokemon_data[:name],
        base_experience: pokemon_data[:base_experience],
        sprite_url: pokemon_data[:sprite_url],
        caught_at: Time.current
      )
      
      {
        success: true,
        message: "Gotcha! You caught #{pokemon_data[:name].capitalize}.",
        pokemon: pokemon_data,
        pokemon_count: user.caught_pokemons.count,
        caught_pokemon_id: caught_pokemon.id
      }
    else
      {
        success: false,
        message: "#{pokemon_data[:name].capitalize} broke free!",
        pokemon: pokemon_data
      }
    end
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def get_user_collection(user_email)
    user = User.find_by(email: user_email)
    return { success: false, error: "User not found" } unless user

    collection = user.caught_pokemons.order(caught_at: :desc).map do |pokemon|
      {
        id: pokemon.id,
        poke_id: pokemon.poke_id,
        name: pokemon.name,
        base_experience: pokemon.base_experience,
        sprite_url: pokemon.sprite_url,
        caught_at: pokemon.caught_at
      }
    end

    {
      success: true,
      user_email: user_email,
      collection: collection,
      count: collection.length
    }
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def release_pokemon(user_email, pokemon_id)
    user = User.find_by(email: user_email)
    return { success: false, error: "User not found" } unless user

    caught_pokemon = user.caught_pokemons.find_by(id: pokemon_id)
    return { success: false, error: "Pokémon not found in user's collection" } unless caught_pokemon

    pokemon_name = caught_pokemon.name
    caught_pokemon.destroy!

    {
      success: true,
      message: "Released #{pokemon_name.capitalize} back to the wild.",
      remaining_count: user.caught_pokemons.count
    }
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def get_pokemon_stats(pokemon_id)
    pokemon_data = PokeApi.fetch_pokemon(pokemon_id)
    
    # Get additional stats from database
    catch_attempts = CaughtPokemon.where(poke_id: pokemon_data[:poke_id]).count
    
    {
      success: true,
      pokemon: pokemon_data,
      database_stats: {
        times_caught: catch_attempts,
        catch_difficulty: CatchLogic.catch_probability(pokemon_data[:base_experience])
      }
    }
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def get_all_collections
    users_with_pokemon = User.joins(:caught_pokemons)
                            .includes(:caught_pokemons)
                            .distinct

    collections = users_with_pokemon.map do |user|
      {
        user_email: user.email,
        pokemon_count: user.caught_pokemons.count,
        collection: user.caught_pokemons.order(caught_at: :desc).map do |pokemon|
          {
            id: pokemon.id,
            poke_id: pokemon.poke_id,
            name: pokemon.name,
            base_experience: pokemon.base_experience,
            sprite_url: pokemon.sprite_url,
            caught_at: pokemon.caught_at
          }
        end
      }
    end

    {
      total_users: collections.length,
      collections: collections
    }
  end

  def get_global_stats
    total_pokemon_caught = CaughtPokemon.count
    total_users = User.count
    users_with_pokemon = User.joins(:caught_pokemons).distinct.count
    
    most_caught_pokemon = CaughtPokemon.group(:name)
                                      .count
                                      .max_by { |_, count| count }

    {
      total_pokemon_caught: total_pokemon_caught,
      total_users: total_users,
      active_users: users_with_pokemon,
      most_caught_pokemon: most_caught_pokemon ? {
        name: most_caught_pokemon[0],
        count: most_caught_pokemon[1]
      } : nil,
      average_pokemon_per_user: users_with_pokemon > 0 ? (total_pokemon_caught.to_f / users_with_pokemon).round(2) : 0
    }
  end

  def error_response(message, id = nil)
    {
      jsonrpc: "2.0",
      id: id,
      error: {
        code: -1,
        message: message
      }
    }
  end
end

# Add CatchLogic class if it doesn't exist
unless defined?(CatchLogic)
  class CatchLogic
    def self.success?(base_experience)
      return true if base_experience.nil? || base_experience == 0
      
      # Higher base experience = harder to catch
      # Scale: 0-300 base exp, with diminishing catch probability
      probability = catch_probability(base_experience)
      rand < probability
    end

    def self.catch_probability(base_experience)
      return 1.0 if base_experience.nil? || base_experience == 0
      
      # Formula: starts at 90% for 0 exp, decreases to ~10% for 300+ exp
      base_prob = 0.9
      difficulty_factor = base_experience / 300.0
      final_prob = base_prob * (1 - (difficulty_factor * 0.8))
      
      # Ensure probability is between 0.1 and 0.9
      [[final_prob, 0.1].max, 0.9].min
    end
  end
end

# Start the server if this file is run directly
if __FILE__ == $0
  server = PokemonMcpServer.new
  server.start
end
