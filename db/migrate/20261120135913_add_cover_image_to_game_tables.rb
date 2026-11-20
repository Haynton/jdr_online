# The cover of a table is picked from the images of app/assets/images/covers: only its name is stored
class AddCoverImageToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_column :game_tables, :cover_image, :string, null: false, default: "sentinelle"
  end
end
