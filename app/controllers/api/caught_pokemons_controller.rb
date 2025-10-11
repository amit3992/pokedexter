module Api
  class CaughtPokemonsController < ApplicationController
    include ApiAuthenticatable
    protect_from_forgery with: :null_session
    skip_before_action :require_login

    def index
      render json: current_api_user.caught_pokemons.order(caught_at: :desc).as_json(
        only: [ :poke_id, :name, :base_experience, :sprite_url, :caught_at ]
      )
    end
  end
end
