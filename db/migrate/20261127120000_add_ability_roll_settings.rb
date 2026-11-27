# The game master decides how free the roll of the abilities is (decision of 27 November): scores typed by hand (a game
# played with real dice) and rolls again, both on by default (as before). When one is off, the server keeps the roll of
# a character being made (characters.ability_rolls: [{ "total", "dice" }]), to check the scores against it
class AddAbilityRollSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :game_tables, :ability_scores_typed, :boolean, default: true, null: false
    add_column :game_tables, :ability_rerolls, :boolean, default: true, null: false
    add_column :characters, :ability_rolls, :jsonb
  end
end
