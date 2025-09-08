module Api
  class CaughtPokemonsController < ApplicationController
    protect_from_forgery with: :null_session
    def index
      render json: current_user.caught_pokemons.order(caught_at: :desc).as_json(
        only: [ :poke_id, :name, :base_experience, :sprite_url, :caught_at ]
      )
    end
  end
end
