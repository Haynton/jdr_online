# The characters of a table (see "Base de données", the design notes): one per player (pc), and the NPCs and
# monsters of the game master (npc, monster, later). The values of the sheet are JSONB, keyed by the fields of
# the template copied into the table. The avatar (Active Storage) comes with the full character creation (card #59)
class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.references :game_table, null: false, foreign_key: true
      t.string :kind, null: false, default: "pc"
      # Only for a player character: the player who plays it
      t.references :participation, foreign_key: true, index: false
      t.string :name, null: false, limit: 60
      t.jsonb :sheet, null: false, default: {}
      t.boolean :visible_to_players, null: false, default: true
      t.text :gm_notes

      t.timestamps
    end

    # One player character per participation
    add_index :characters, :participation_id, unique: true, where: "kind = 'pc'",
                                              name: "index_characters_one_pc_per_participation"
    # The NPCs and monsters of a table
    add_index :characters, %i[game_table_id kind]
    add_check_constraint :characters, "kind IN ('pc', 'npc', 'monster')", name: "characters_kind_check"
  end
end
