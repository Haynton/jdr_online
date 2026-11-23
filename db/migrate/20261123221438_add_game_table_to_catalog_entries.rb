# The catalog of a table (decision of 23 November): an entry belongs either to a template (its catalog, as before) or
# to a table (a copy changed for that table, or an entry the game master added), never both. The table also keeps the
# entries of its template it does not use, by kind ({ "spell" => ["fireball"] }): nothing is deleted
class AddGameTableToCatalogEntries < ActiveRecord::Migration[8.1]
  def change
    change_column_null :catalog_entries, :sheet_template_id, true
    add_reference :catalog_entries, :game_table, foreign_key: true, index: false
    add_index :catalog_entries, %i[game_table_id kind key], unique: true, where: "game_table_id IS NOT NULL"
    add_check_constraint :catalog_entries, "(sheet_template_id IS NULL) <> (game_table_id IS NULL)",
                         name: "catalog_entries_one_owner_check"
    add_column :game_tables, :disabled_catalog_keys, :jsonb, default: {}, null: false
  end
end
