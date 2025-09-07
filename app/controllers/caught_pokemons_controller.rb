class CaughtPokemonsController < ApplicationController
    def index
      @caught = current_user.caught_pokemons.order(caught_at: :desc)
    end
  end