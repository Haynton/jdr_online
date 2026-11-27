# The magic items a character created above level 1 picks at the step of the equipment (decision of 27 November):
# for each place its level gives (a rarity and a number), the item picked, or a magic put on an item of its equipment
class AddStartingMagicItemsToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :starting_magic_items, :jsonb, default: {}, null: false
  end
end
