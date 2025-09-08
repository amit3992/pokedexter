class CaughtPokemonsController < ApplicationController
  def index
    @caught = current_user.caught_pokemons.order(caught_at: :desc)
  end

  def release
    pokemon = current_user.caught_pokemons.find_by(id: params[:id])
    if pokemon
      pokemon.destroy
      flash[:notice] = "#{pokemon.name.capitalize} was released back into the wild."
    else
      flash[:alert] = "Couldn't find that Pokémon in your collection."
    end
    redirect_to caught_path
  end
end
