# The spells a character knows or prepares, copied out of the catalog of the template when chosen (decision): a copy
# never changes when the catalog does. A list in JSONB ({ "key", "name", "level", "description", "properties" }):
# a spell is pointed to by nothing else, so it needs no table of its own
class AddSpellsToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :spells, :jsonb, null: false, default: []
  end
end
