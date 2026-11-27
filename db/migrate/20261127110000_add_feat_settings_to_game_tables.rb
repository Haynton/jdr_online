# The game master turns the feats on or off for the table (decision of 27 November): the origin feats (the one of the
# background, the one the human picks) and the feats at the levels that improve the abilities. On by default, as the
# rules of 2024 play them
class AddFeatSettingsToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_column :game_tables, :origin_feats, :boolean, default: true, null: false
    add_column :game_tables, :level_feats, :boolean, default: true, null: false
  end
end
