# The fields of a spell (level, school, classes...), declared by the template like those of an item (item_fields),
# and copied into a game table with the rest of the template. The spells themselves are rows of catalog_entries
class AddSpellFieldsToSheetTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :sheet_templates, :spell_fields, :jsonb, null: false, default: {}
  end
end
