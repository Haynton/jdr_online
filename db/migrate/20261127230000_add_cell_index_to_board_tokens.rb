class AddCellIndexToBoardTokens < ActiveRecord::Migration[8.1]
  def change
    add_index :board_tokens, %i[game_map_id column row], unique: true, name: "index_board_tokens_on_cell"
  end
end
