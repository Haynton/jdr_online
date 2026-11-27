class CreateBoardTokens < ActiveRecord::Migration[8.1]
  def change
    create_board_tokens
    add_check_constraint :board_tokens, "\"column\" >= 0 AND \"row\" >= 0", name: "board_tokens_cell_check"
    add_index :board_tokens, %i[game_map_id column row], unique: true, name: "index_board_tokens_on_cell"
    add_token_counters_to_game_maps
  end

  private

  def create_board_tokens
    create_table :board_tokens do |t|
      t.references :game_map, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :character, null: false, foreign_key: { on_delete: :cascade }
      t.integer :column, :row, null: false
      t.boolean :hidden, null: false, default: true
      t.integer :placement, null: false, default: 0
      t.integer :number
      t.string :name, limit: 60
      t.timestamps
    end
  end

  def add_token_counters_to_game_maps
    add_column :game_maps, :tokens_copied_at, :datetime
    add_column :game_maps, :token_counters, :jsonb, null: false, default: {}
    add_column :game_maps, :tokens_placed, :integer, null: false, default: 0
  end
end
