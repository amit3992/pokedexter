module Api
  class UsersCaughtPokemonsController < ApplicationController
    protect_from_forgery with: :null_session
    skip_before_action :require_login

    # GET /api/users/caught_pokemons?email=user@example.com
    def index
      if params[:email].blank?
        render json: { error: "Email parameter is required" }, status: :unprocessable_entity
        return
      end

      user = User.find_by(email: params[:email])

      if user.nil?
        render json: { error: "User not found" }, status: :not_found
        return
      end

      caught_pokemons = user.caught_pokemons.order(caught_at: :desc)
      render json: caught_pokemons.as_json(
        only: [ :id, :poke_id, :name, :base_experience, :sprite_url, :caught_at ]
      )
    end

    # DELETE /api/users/caught_pokemons/:id?email=user@example.com
    def release
      if params[:email].blank?
        render json: { error: "Email parameter is required" }, status: :unprocessable_entity
        return
      end

      user = User.find_by(email: params[:email])

      if user.nil?
        render json: { error: "User not found" }, status: :not_found
        return
      end

      pokemon = user.caught_pokemons.find_by(id: params[:id])

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
