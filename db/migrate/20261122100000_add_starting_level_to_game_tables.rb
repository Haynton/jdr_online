# The level of the characters when the game begins, chosen by the game master (decision): players no longer type
# it on their sheet. Every table made before starts at level 1 (default), and the database only allows 1 to 20
class AddStartingLevelToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_column :game_tables, :starting_level, :integer, null: false, default: 1
    add_check_constraint :game_tables, "starting_level BETWEEN 1 AND 20", name: "game_tables_starting_level_check"
  end
end
