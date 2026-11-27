# The rules of the game by default, more freedom when the game master wants it (decision of 27 November): what an option
# picked gives (the saving throws of a class, the skills of a background) stays ticked unless the table lets the
# players change it, and a roll of the abilities is rolled once unless the table lets them roll again
class AddRulesDefaultsToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_column :game_tables, :players_change_given_choices, :boolean, default: false, null: false
    change_column_default :game_tables, :ability_rerolls, from: true, to: false
  end
end
