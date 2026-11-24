# The maps of a table, added by its game master at the step Maps: a name, an image (Active Storage), and the grid the
# board will snap the tokens to: the size of a cell in pixels of the image, shown or not. In the order they were added
class CreateGameMaps < ActiveRecord::Migration[8.1]
  def change
    create_table :game_maps do |t|
      t.references :game_table, null: false, foreign_key: true
      t.string :name, null: false, limit: 60
      t.integer :grid_cell_size, null: false, default: 50
      t.boolean :grid_visible, null: false, default: true
      t.timestamps
    end
    add_check_constraint :game_maps, "grid_cell_size BETWEEN 10 AND 500", name: "game_maps_grid_cell_size_check"
  end
end
