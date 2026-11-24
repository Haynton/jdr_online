# The way a player gets the hit points of the levels after the first when the table lets them pick it (a type of
# HitPointMethods: average, roll), and the hit dice they rolled, with the die they were rolled with
# ({ "sides" => 8, "results" => [5, 3] }): a roll is made once (decision), and holds while the class and the level stay
class AddHitPointsToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :hit_point_method, :string
    add_column :characters, :hit_point_rolls, :jsonb, null: false, default: {}
  end
end
