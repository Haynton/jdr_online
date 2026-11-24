# A map of a table may now be a copy of a map of « Mes cartes » (a drawing, or a picture with its grid set on it): the
# map it comes from (emptied if that one is deleted: the table keeps its copy), the size of its grid and its layout.
# The maps sent as a picture before keep their image and the size of their cells, without a grid or a layout
class AddDrawingToGameMaps < ActiveRecord::Migration[8.1]
  def change
    add_reference :game_maps, :map_template, foreign_key: { on_delete: :nullify }
    add_column :game_maps, :columns, :integer
    add_column :game_maps, :rows, :integer
    add_column :game_maps, :layout, :jsonb
    add_check_constraint :game_maps, "columns IS NULL OR columns BETWEEN 10 AND 60", name: "game_maps_columns_check"
    add_check_constraint :game_maps, "rows IS NULL OR rows BETWEEN 10 AND 60", name: "game_maps_rows_check"
  end
end
