# The spellbook of a wizard (decision of 27 November, SRD 5.2.1): a copy of each level 1+ spell written in it, as the
# spells prepared (characters.spells), which are picked among them
class AddSpellbookToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :spellbook, :jsonb, default: [], null: false
  end
end
