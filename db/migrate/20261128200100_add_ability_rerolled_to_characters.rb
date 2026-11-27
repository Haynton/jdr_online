# A roll of the abilities may be rolled again only once, when the table allows it (decision of 27 November): the
# character remembers it did
class AddAbilityRerolledToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :ability_rerolled, :boolean, default: false, null: false
  end
end
