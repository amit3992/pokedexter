class PokeApi
    BASE = "https://pokeapi.co/api/v2".freeze
  
    def self.fetch_pokemon(id_or_name)
      resp = HTTPX.get("#{BASE}/pokemon/#{id_or_name}/")
      raise "PokeAPI error: #{resp.status}" unless resp.status == 200
  
      json = resp.json
      {
        poke_id:         json["id"],
        name:            json["name"],
        base_experience: json["base_experience"],
        sprite_url:      json.dig("sprites", "front_default")
      }
    end
  
    def self.random_id(max: 898) # Gen 1–8 common set pokemons
      rand(1..max)
    end
  end