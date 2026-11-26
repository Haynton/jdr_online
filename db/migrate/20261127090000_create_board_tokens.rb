class CreateBoardTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :board_tokens do |t|
      t.references :game_map, null: false, foreign_key: { on_delete: :cascade }
      t.references :character, null: false, foreign_key: { on_delete: :cascade }
      t.integer :column, null: false
      t.integer :row, null: false
      t.boolean :hidden, null: false, default: true
      t.timestamps
    end
    add_check_constraint :board_tokens, "\"column\" >= 0 AND \"row\" >= 0", name: "board_tokens_cell_check"

    add_column :game_maps, :tokens_copied_at, :datetime
  end
end
