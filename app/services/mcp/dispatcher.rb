module Mcp
  class Dispatcher
    PROTOCOL_VERSIONS = %w[2024-11-05 2025-03-26 2025-06-18].freeze
    SERVER_INFO = { name: "pokemon-mcp-server", version: "2.0.0" }.freeze

    JSONRPC_PARSE_ERROR      = -32700
    JSONRPC_INVALID_REQUEST  = -32600
    JSONRPC_METHOD_NOT_FOUND = -32601
    JSONRPC_INVALID_PARAMS   = -32602
    JSONRPC_INTERNAL_ERROR   = -32603

    # Returns a JSON-RPC response hash, or nil for notifications.
    def handle(request)
      return error(nil, JSONRPC_INVALID_REQUEST, "Request must be a JSON object") unless request.is_a?(Hash)

      method = request["method"]
      params = request["params"] || {}
      id     = request["id"]
      notification = !request.key?("id")

      result = dispatch(method, params, id)
      notification ? nil : result
    end

    private

    def dispatch(method, params, id)
      case method
      when "initialize"               then initialize_response(id, params)
      when "notifications/initialized" then nil
      when "ping"                     then ok(id, {})
      when "tools/list"               then tools_list(id)
      when "tools/call"               then tools_call(id, params)
      when "resources/list"           then resources_list(id)
      when "resources/read"           then resources_read(id, params)
      else
        error(id, JSONRPC_METHOD_NOT_FOUND, "Unknown method: #{method}")
      end
    rescue => e
      Rails.logger.error("[MCP] #{method} failed: #{e.class}: #{e.message}")
      error(id, JSONRPC_INTERNAL_ERROR, e.message)
    end

    def initialize_response(id, params)
      requested = params["protocolVersion"]
      negotiated = PROTOCOL_VERSIONS.include?(requested) ? requested : PROTOCOL_VERSIONS.last
      ok(id, {
        protocolVersion: negotiated,
        capabilities: { tools: {}, resources: {} },
        serverInfo: SERVER_INFO
      })
    end

    def tools_list(id)
      ok(id, tools: [
        {
          name: "search_pokemon",
          description: "Look up a Pokémon by name or numeric ID via PokéAPI. Returns name, id, base experience, sprite URL.",
          inputSchema: {
            type: "object",
            properties: { query: { type: "string", description: "Pokémon name (e.g. 'pikachu') or numeric id." } },
            required: [ "query" ]
          }
        },
        {
          name: "get_random_pokemon",
          description: "Fetch a random Pokémon from PokéAPI. Useful when the user wants to discover one to try catching.",
          inputSchema: {
            type: "object",
            properties: { max_id: { type: "integer", description: "Highest Pokémon id to consider.", default: 898 } }
          }
        },
        {
          name: "attempt_catch_pokemon",
          description: "Attempt to catch a Pokémon for a specific user. Probability decays with the Pokémon's base experience. The user is capped at 10 caught Pokémon.",
          inputSchema: {
            type: "object",
            properties: {
              pokemon_id: { type: "string", description: "Name or numeric id of the Pokémon to catch." },
              user_email: { type: "string", description: "Email of the user attempting the catch (use the chatting contact's email)." }
            },
            required: [ "pokemon_id", "user_email" ]
          }
        },
        {
          name: "get_user_collection",
          description: "List the Pokémon caught by a specific user, newest first.",
          inputSchema: {
            type: "object",
            properties: {
              user_email: { type: "string", description: "Email of the user whose collection to fetch." }
            },
            required: [ "user_email" ]
          }
        },
        {
          name: "release_pokemon",
          description: "Release one of a user's caught Pokémon back to the wild. The pokemon_id here is the database row id, not the PokéAPI id — get it from get_user_collection first.",
          inputSchema: {
            type: "object",
            properties: {
              user_email: { type: "string", description: "Email of the user releasing the Pokémon." },
              pokemon_id: { type: "integer", description: "Database id from get_user_collection." }
            },
            required: [ "user_email", "pokemon_id" ]
          }
        },
        {
          name: "get_pokemon_stats",
          description: "Get a Pokémon's PokéAPI details plus catch probability and the count of times it has been successfully caught across all users.",
          inputSchema: {
            type: "object",
            properties: { pokemon_id: { type: "string", description: "Name or numeric id of the Pokémon." } },
            required: [ "pokemon_id" ]
          }
        }
      ])
    end

    def tools_call(id, params)
      name = params["name"]
      args = params["arguments"] || {}

      result = time_log("tool=#{name}") do
        case name
        when "search_pokemon"        then search_pokemon(args["query"])
        when "get_random_pokemon"    then get_random_pokemon(args["max_id"] || 898)
        when "attempt_catch_pokemon" then attempt_catch_pokemon(args["pokemon_id"], args["user_email"])
        when "get_user_collection"   then get_user_collection(args["user_email"])
        when "release_pokemon"       then release_pokemon(args["user_email"], args["pokemon_id"])
        when "get_pokemon_stats"     then get_pokemon_stats(args["pokemon_id"])
        else
          :__unknown_tool__
        end
      end

      return error(id, JSONRPC_METHOD_NOT_FOUND, "Unknown tool: #{name}") if result == :__unknown_tool__

      ok(id, content: [ { type: "text", text: JSON.pretty_generate(result) } ])
    end

    def resources_list(id)
      ok(id, resources: [
        {
          uri: "pokemon://stats/global",
          name: "Global Statistics",
          description: "Aggregate Pokémon catching statistics across all users."
        }
      ])
    end

    def resources_read(id, params)
      uri = params["uri"]
      payload = time_log("resource=#{uri}") do
        case uri
        when "pokemon://stats/global" then global_stats
        else :__unknown_resource__
        end
      end

      return error(id, JSONRPC_INVALID_PARAMS, "Unknown resource: #{uri}") if payload == :__unknown_resource__

      ok(id, contents: [ { uri: uri, mimeType: "application/json", text: JSON.pretty_generate(payload) } ])
    end

    # ---- tool implementations ----

    def search_pokemon(query)
      return { success: false, error: "query is required" } if query.blank?
      { success: true, pokemon: PokeApi.fetch_pokemon(query) }
    rescue => e
      { success: false, error: e.message }
    end

    def get_random_pokemon(max_id)
      random_id = PokeApi.random_id(max: max_id.to_i)
      { success: true, random_id: random_id, pokemon: PokeApi.fetch_pokemon(random_id) }
    rescue => e
      { success: false, error: e.message }
    end

    def attempt_catch_pokemon(pokemon_id, user_email)
      user = lookup_user(user_email)
      return user_not_found(user_email) unless user

      if user.caught_pokemons.count >= 10
        return { success: false, limit_reached: true,
                 error: "User already has 10 Pokémon. Release some before catching more." }
      end

      data = PokeApi.fetch_pokemon(pokemon_id)
      if CatchLogic.success?(data[:base_experience])
        record = CaughtPokemon.create!(
          user: user, poke_id: data[:poke_id], name: data[:name],
          base_experience: data[:base_experience], sprite_url: data[:sprite_url],
          caught_at: Time.current
        )
        { success: true, message: "Gotcha! #{user.email} caught #{data[:name].capitalize}.",
          pokemon: data, caught_pokemon_id: record.id, pokemon_count: user.caught_pokemons.count }
      else
        { success: false, message: "#{data[:name].capitalize} broke free!", pokemon: data }
      end
    rescue => e
      { success: false, error: e.message }
    end

    def get_user_collection(user_email)
      user = lookup_user(user_email)
      return user_not_found(user_email) unless user

      collection = user.caught_pokemons.order(caught_at: :desc).map do |p|
        { id: p.id, poke_id: p.poke_id, name: p.name, base_experience: p.base_experience,
          sprite_url: p.sprite_url, caught_at: p.caught_at }
      end
      { success: true, user_email: user.email, count: collection.length, collection: collection }
    rescue => e
      { success: false, error: e.message }
    end

    def release_pokemon(user_email, pokemon_id)
      user = lookup_user(user_email)
      return user_not_found(user_email) unless user

      record = user.caught_pokemons.find_by(id: pokemon_id.to_i)
      return { success: false, error: "Pokémon not found in user's collection" } unless record

      name = record.name
      record.destroy!
      { success: true, message: "#{name.capitalize} was released back into the wild.",
        remaining_count: user.caught_pokemons.count }
    rescue => e
      { success: false, error: e.message }
    end

    def get_pokemon_stats(pokemon_id)
      data = PokeApi.fetch_pokemon(pokemon_id)
      successful_catches = CaughtPokemon.where(poke_id: data[:poke_id]).count
      { success: true, pokemon: data,
        database_stats: {
          successful_catches: successful_catches,
          catch_probability: CatchLogic.catch_probability(data[:base_experience])
        } }
    rescue => e
      { success: false, error: e.message }
    end

    def global_stats
      total_caught = CaughtPokemon.count
      total_users  = User.count
      active_users = User.joins(:caught_pokemons).distinct.count
      most_caught  = CaughtPokemon.group(:name).count.max_by { |_, c| c }
      {
        total_pokemon_caught: total_caught,
        total_users: total_users,
        active_users: active_users,
        most_caught_pokemon: most_caught ? { name: most_caught[0], count: most_caught[1] } : nil,
        average_pokemon_per_user: active_users > 0 ? (total_caught.to_f / active_users).round(2) : 0
      }
    end

    # ---- helpers ----

    def lookup_user(email)
      return nil if email.blank?
      User.find_by(email: email.to_s.downcase.strip)
    end

    def user_not_found(email)
      { success: false, error: "User not found", user_email: email }
    end

    def time_log(label)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result  = yield
      elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1)
      Rails.logger.info("[mcp.timing] #{label} ms=#{elapsed}")
      result
    end

    def ok(id, result)
      { jsonrpc: "2.0", id: id, result: result }
    end

    def error(id, code, message)
      { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
    end
  end
end
