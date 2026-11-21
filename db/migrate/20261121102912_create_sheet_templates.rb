# The library of character sheet templates. A template is a document (JSONB): its fields are invented by
# the game master, so they cannot be SQL columns. A table plays with a frozen copy of it (template_snapshot)
class CreateSheetTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :sheet_templates do |t|
      t.string :name, null: false, limit: 60
      # Empty for a template provided by the app (seed), otherwise the game master who made it
      t.references :owner, foreign_key: { to_table: :users }
      # The template this one was adapted from
      t.references :parent, foreign_key: { to_table: :sheet_templates }
      t.jsonb :character_fields, null: false, default: {}
      t.jsonb :npc_fields, null: false, default: {}
      t.jsonb :item_fields, null: false, default: {}
      t.jsonb :rest_rules, null: false, default: []
      t.jsonb :level_thresholds, null: false, default: []
      t.jsonb :preset_characters, null: false, default: []
      t.jsonb :preset_items, null: false, default: []

      t.timestamps
    end
  end
end
