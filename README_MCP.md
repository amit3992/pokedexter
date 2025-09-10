# Pokémon MCP Server

This directory contains an MCP (Model Context Protocol) server that exposes your Pokémon app functionality to AI assistants.

## What is MCP?

MCP (Model Context Protocol) allows AI assistants to interact with external systems through standardized tools and resources. Your Pokémon app can now be used by AI assistants to:

- Search and discover Pokémon
- Attempt to catch Pokémon with realistic probability
- Manage user collections
- Access Pokémon statistics and data

## Available Tools

### `search_pokemon`
Search for a Pokémon by name or ID from the PokéAPI.

**Parameters:**
- `query` (string): Pokémon name or ID

### `get_random_pokemon`
Get a random Pokémon from the available set.

**Parameters:**
- `max_id` (integer, optional): Maximum Pokémon ID (default: 898)

### `attempt_catch_pokemon`
Attempt to catch a Pokémon with probability-based success.

**Parameters:**
- `pokemon_id` (string): ID or name of Pokémon to catch
- `user_email` (string): Email of the user attempting to catch

### `get_user_collection`
Retrieve a user's collection of caught Pokémon.

**Parameters:**
- `user_email` (string): Email of the user

### `release_pokemon`
Release a Pokémon from a user's collection.

**Parameters:**
- `user_email` (string): Email of the user
- `pokemon_id` (integer): Database ID of the caught Pokémon

### `get_pokemon_stats`
Get detailed statistics for a specific Pokémon.

**Parameters:**
- `pokemon_id` (string): ID or name of the Pokémon

## Available Resources

### `pokemon://collections`
Access all user collections and their Pokémon.

### `pokemon://stats/global`
Global statistics about Pokémon catching across all users.

## Setup Instructions

### 1. Install Dependencies
Make sure your Rails app is set up and running:

```bash
bundle install
bin/rails db:create db:migrate db:seed
```

### 2. Test the MCP Server
You can test the server manually:

```bash
cd /Users/apk/dev/ruby/pokeapp
ruby mcp_server.rb
```

Then send MCP protocol messages via STDIN. Example:
```json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}
```

### 3. Configure with AI Assistants

#### For Claude Desktop
Add this to your Claude Desktop configuration:

```json
{
  "mcpServers": {
    "pokemon": {
      "command": "ruby",
      "args": ["mcp_server.rb"],
      "cwd": "/Users/apk/dev/ruby/pokeapp",
      "env": {
        "RAILS_ENV": "development"
      }
    }
  }
}
```

#### For Other MCP Clients
Use the provided `mcp_server_config.json` as a reference for configuration.

## Usage Examples

Once connected to an AI assistant, you can:

1. **Discover Pokémon**: "Show me a random Pokémon"
2. **Search**: "Find information about Pikachu"
3. **Catch Pokémon**: "Try to catch Charizard for user ash.ketchum@pokemon.com"
4. **Manage Collections**: "Show me all Pokémon caught by misty.waterflower@cerulean.gym"
5. **View Statistics**: "What are the global catching statistics?"

## Features

- **Probability-based Catching**: Harder to catch Pokémon with higher base experience
- **Collection Limits**: Users can only hold 10 Pokémon at a time
- **Real-time Data**: Integrates with your existing Rails database
- **User Management**: Works with your existing user system
- **Statistics**: Provides insights into catching patterns

## Technical Details

The MCP server:
- Runs as a standalone Ruby process
- Communicates via JSON-RPC over STDIN/STDOUT
- Integrates with your existing Rails models and services
- Handles errors gracefully with proper MCP responses
- Supports both tools (functions) and resources (data access)

## Troubleshooting

### Server Won't Start
- Ensure Rails environment loads properly: `bundle exec rails console`
- Check that all dependencies are installed: `bundle install`
- Verify database is accessible: `bin/rails db:migrate:status`

### Tools Not Working
- Check that users exist in the database (run `bin/rails db:seed`)
- Verify PokeAPI is accessible
- Check Rails logs for detailed error messages

### MCP Client Issues
- Ensure the working directory path is correct in configuration
- Verify Ruby is in the system PATH
- Check that the MCP client supports the protocol version (2024-11-05)
