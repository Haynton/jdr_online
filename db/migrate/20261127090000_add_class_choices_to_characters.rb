# The options a player's character picked in the groups of choices its class gives (decision of 27 November:
# invocations, metamagic, prey of the hunter, land of the circle), by key of the group: { "metamagic" => ["subtle-spell"] }.
# Nothing picked by default
class AddClassChoicesToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :class_choices, :jsonb, default: {}, null: false
  end
end
