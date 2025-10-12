module Api
  class PokemonsController < ApplicationController
    protect_from_forgery with: :null_session
    skip_before_action :require_login

    # GET /api/pokemon/:name
    # Fetch Pokemon information by name (case-insensitive)
    def show
      name = params[:name]

      if name.blank?
        render json: { error: "Pokemon name is required" }, status: :unprocessable_entity
        return
      end

      pokemon = PokeApi.fetch_pokemon_by_name(name)
      render json: pokemon, status: :ok
    rescue => e
      render json: { error: e.message }, status: :not_found
    end
  end
end
