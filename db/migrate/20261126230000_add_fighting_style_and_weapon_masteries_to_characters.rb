# The fighting style a character picked (the key of a style its template declares: archery) and the kinds of weapons
# whose mastery property it uses (["longswords", "shortbows"]), chosen at the step of the skills and changed in the
# game room (CharacterSheets::WeaponMasteries)
class AddFightingStyleAndWeaponMasteriesToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :fighting_style, :string
    add_column :characters, :weapon_masteries, :jsonb, default: [], null: false
  end
end
