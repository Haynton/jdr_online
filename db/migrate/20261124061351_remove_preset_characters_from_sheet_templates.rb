# The ready-made NPCs of a template are now a catalog (kind monster, the bestiary), copied into a table by its game
# master: one source, the column is no longer read
class RemovePresetCharactersFromSheetTemplates < ActiveRecord::Migration[8.1]
  def change
    remove_column :sheet_templates, :preset_characters, :jsonb, default: [], null: false
  end
end
