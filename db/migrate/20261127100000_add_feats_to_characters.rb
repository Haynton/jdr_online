# The feats a player's character took beside the origin feat of its background (decision of 27 November): at a level
# that gives an Ability Score Improvement, the improvement itself or another feat; at level 19 an epic boon; an origin
# feat for the human. One entry per feat taken, with what was picked for it:
# [{ "key" => "grappler", "level" => 4, "abilities" => { "strength" => 1 } }]
class AddFeatsToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :feats, :jsonb, default: [], null: false
  end
end
