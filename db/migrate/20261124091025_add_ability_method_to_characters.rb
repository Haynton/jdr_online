# The way a player gets the scores of their character when the table lets them pick it (a type of AbilityMethods:
# roll, standard_array, point_buy). Empty when the table picks it
class AddAbilityMethodToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :ability_method, :string
  end
end
