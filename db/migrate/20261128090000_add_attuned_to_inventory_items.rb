# The attunement of a magic item (decision of 27 November, SRD 5.2.1): an item that requires it works only once its
# character is attuned to it, a few at a time (the template says how many). A switch « Lié » in the inventory of the
# game room
class AddAttunedToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_items, :attuned, :boolean, default: false, null: false
  end
end
