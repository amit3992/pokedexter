class CreateCaughtPokemons < ActiveRecord::Migration[8.0]
  def change
    create_table :caught_pokemons do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :poke_id
      t.string :name
      t.integer :base_experience
      t.string :sprite_url
      t.datetime :caught_at

      t.timestamps
    end
  end
end
