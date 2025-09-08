class PokemonsController < ApplicationController
    protect_from_forgery with: :exception
  
    # GET /pokemon/random
    def random
      @pokemon = PokeApi.fetch_pokemon(PokeApi.random_id)
    rescue => e
      flash.now[:alert] = e.message
      @pokemon = nil
    end
  
    # POST /pokemon/:id/catch
    def catch
      # Check if user already has 10 Pokémon
      if current_user.caught_pokemons.count >= 10
        render json: { 
          success: false, 
          error: "You already have 10 Pokémon! Release some before catching more.",
          limit_reached: true 
        }, status: :unprocessable_entity
        return
      end

      data = PokeApi.fetch_pokemon(params[:id])
      if CatchLogic.success?(data[:base_experience])
        CaughtPokemon.create!(
          user: current_user,
          poke_id: data[:poke_id],
          name: data[:name],
          base_experience: data[:base_experience],
          sprite_url: data[:sprite_url],
          caught_at: Time.current
        )
        render json: { 
          success: true, 
          message: "Gotcha! You caught #{data[:name].capitalize}.",
          pokemon_count: current_user.caught_pokemons.count
        }
      else
        render json: { success: false, message: "#{data[:name].capitalize} broke free!" }, status: :ok
      end
    rescue => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end