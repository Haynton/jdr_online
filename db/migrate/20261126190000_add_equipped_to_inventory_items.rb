# What a character wears and holds: the armour and the shield count in its armour class, each weapon gives an attack.
# Not equipped by default: the items of the characters made before stay in the bag until their player equips them
class AddEquippedToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_items, :equipped, :boolean, default: false, null: false
  end
end
