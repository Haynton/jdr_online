# The items a character carries (decision: a line per item, not a JSONB list: the game will change them one by one,
# their quantities, and other features will point to them). Each line is a copy of its catalog entry (key, name,
# description, properties), which a change of the catalog never changes; quantity counts the same items (20 arrows)
class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.references :character, null: false, foreign_key: true
      t.string :key
      t.string :name, null: false, limit: 60
      t.text :description
      t.jsonb :properties, null: false, default: {}
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end

    add_check_constraint :inventory_items, "quantity > 0", name: "inventory_items_quantity_positive"
  end
end
