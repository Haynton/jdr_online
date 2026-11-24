# The maps of a game master (« Mes cartes »), drawn in the map editor and copied into a table to play on: a name, the
# size of the grid (columns and rows of square cells), and the drawing (layout: floors and edges, in JSONB, checked by
# MapLayoutValidator). Deleted with their owner
class CreateMapTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :map_templates do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false, limit: 60
      t.integer :columns, null: false, default: 28
      t.integer :rows, null: false, default: 21
      t.jsonb :layout, null: false, default: {}
      t.timestamps
    end
    add_check_constraint :map_templates, "columns BETWEEN 10 AND 60", name: "map_templates_columns_check"
    add_check_constraint :map_templates, "rows BETWEEN 10 AND 60", name: "map_templates_rows_check"
  end
end
