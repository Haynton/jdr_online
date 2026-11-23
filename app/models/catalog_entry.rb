# A spell, an item, an NPC, a monster or a feature of a catalog (decision of 22 November: one shared table, not a list
# copied into every game table). It belongs to a template (its catalog) or to a game table (decision of 23 November:
# a copy of an entry of its template changed for that table, same key, or an entry the game master added), never both
# (checked by the database too). What a table offers: Catalogs::TableCatalog. Its properties follow the fields the
# template declares for its kind (spell_fields for a spell; for a table, the copy of its template), checked by
# CatalogPropertiesValidator. What enters the game is copied out of it (a spell into characters.spells): changing the
# catalog never changes a character
class CatalogEntry < ApplicationRecord
  KINDS = %w[spell item npc monster feature].freeze
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # The column of the template that declares the properties of each kind (the other kinds: later)
  PROPERTY_FIELDS_COLUMNS = { "spell" => "spell_fields", "item" => "item_fields" }.freeze

  belongs_to :sheet_template, optional: true
  belongs_to :game_table, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :key, presence: true, uniqueness: { scope: %i[sheet_template_id game_table_id kind] }
  validate :belongs_to_one_catalog
  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates_with CatalogPropertiesValidator

  scope :spells, -> { where(kind: "spell") }
  # The spells a class can learn: its option of the class list is among their classes ("Magicien")
  scope :for_class, ->(class_option) { where("properties -> 'classes' ? :class_option", class_option: class_option) }
  scope :of_level, ->(levels) { where("(properties ->> 'level')::integer IN (?)", Array(levels)) }
  # Cantrips first, then by level, then by name
  scope :by_level_and_name, -> { order(Arel.sql("(properties ->> 'level')::integer"), :name) }

  def level
    properties["level"]
  end

  # The fields the template declares for this kind (spell_fields for a spell), read in the copy of a table for its own
  # entries; nil for a kind it does not describe yet
  def property_fields
    column = PROPERTY_FIELDS_COLUMNS[kind]
    return unless column && (sheet_template || game_table)

    declared = sheet_template ? sheet_template.public_send(column) : game_table.template_snapshot.to_h[column]
    declared.to_h["fields"].to_a
  end

  # CatalogPropertiesValidator adds its errors per property ("properties.level"), so that each one shows under its
  # field. Rails reads the refused value to build the message: it is in the properties, not in a method of that name
  def read_attribute_for_validation(attribute)
    return super unless attribute.to_s.start_with?("properties.")

    properties[attribute.to_s.delete_prefix("properties.")]
  end

  private

  def belongs_to_one_catalog
    errors.add(:base, :one_catalog) unless sheet_template_id.nil? ^ game_table_id.nil?
  end
end
