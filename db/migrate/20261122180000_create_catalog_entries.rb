# The catalogs of a template (decision of 22 November): one shared table rather than a list copied into the JSON of
# every game table, which would grow with the number of tables (about 300 spells for the SRD alone). One row per spell,
# item, NPC, monster or feature (feats, class features), for one template: a predefined template is written in one
# language, so its catalog is too, without a locale column. The shape of properties is declared by the template
# (spell_fields for a spell) and checked by the app (CatalogPropertiesValidator)
class CreateCatalogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_entries do |t|
      t.references :sheet_template, null: false, foreign_key: true, index: false
      t.string :kind, null: false
      t.string :key, null: false
      t.string :name, null: false, limit: 60
      t.text :description
      t.jsonb :properties, null: false, default: {}
      t.timestamps
    end

    add_index :catalog_entries, %i[sheet_template_id kind key], unique: true
    add_index :catalog_entries, %i[sheet_template_id kind name]
    add_index :catalog_entries, :properties, using: :gin
    add_check_constraint :catalog_entries, "kind IN ('spell', 'item', 'npc', 'monster', 'feature')",
                         name: "catalog_entries_kind_check"
  end
end
