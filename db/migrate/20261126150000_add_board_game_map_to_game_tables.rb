# The map the game master puts on the board of the game room, seen by everyone at the table (one at a time). Emptied
# when that map is deleted: the board waits for another one
class AddBoardGameMapToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_reference :game_tables, :board_game_map, foreign_key: { to_table: :game_maps, on_delete: :nullify }
  end
end
