module Api
  class UsersCaughtPokemonsController < ApplicationController
    include ApiAuthenticatable
    protect_from_forgery with: :null_session
    skip_before_action :require_login

    # GET /api/users/caught_pokemons
    # Requires JWT authentication via Authorization header
    def index
      caught_pokemons = current_api_user.caught_pokemons.order(caught_at: :desc)
      render json: caught_pokemons.as_json(
        only: [ :id, :poke_id, :name, :base_experience, :sprite_url, :caught_at ]
      )
    end

    # DELETE /api/users/caught_pokemons/:id
    # Requires JWT authentication via Authorization header
    def release
      pokemon = current_api_user.caught_pokemons.find_by(id: params[:id])

      if pokemon.nil?
        render json: { error: "Pokémon not found or does not belong to this user" }, status: :not_found
        return
      end

      pokemon_name = pokemon.name
      pokemon.destroy

      render json: {
        message: "#{pokemon_name.capitalize} was released back into the wild.",
        released_pokemon: {
          id: params[:id],
          name: pokemon_name
        }
      }, status: :ok
    end
  end
end
