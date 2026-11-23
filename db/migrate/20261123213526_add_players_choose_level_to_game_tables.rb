# The switch of the step Settings: the players choose the level of their character on the first page of its
# creation, starting from the starting level of the table. Off by default: the tables made before keep their level
class AddPlayersChooseLevelToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_column :game_tables, :players_choose_level, :boolean, default: false, null: false
  end
end
