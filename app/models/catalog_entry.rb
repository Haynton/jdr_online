# A spell, an item, an NPC, a monster or a feature of the catalog of a template (decision of 22 November: one shared
# table, not a list copied into every game table). Its properties follow the fields the template declares for its kind
# (spell_fields for a spell), checked by CatalogPropertiesValidator. What enters the game is copied out of it (a spell
# into characters.spells): changing the catalog never changes a character
class CatalogEntry < ApplicationRecord
  KINDS = %w[spell item npc monster feature].freeze
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # The column of the template that declares the properties of each kind (the other kinds: later)
  PROPERTY_FIELDS_COLUMNS = { "spell" => "spell_fields" }.freeze

  belongs_to :sheet_template

  validates :kind, inclusion: { in: KINDS }
  validates :key, presence: true, uniqueness: { scope: %i[sheet_template_id kind] }
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

  # The fields the template declares for this kind (spell_fields for a spell); nil for a kind it does not describe yet
  def property_fields
    column = PROPERTY_FIELDS_COLUMNS[kind]
    return unless column && sheet_template

    sheet_template.public_send(column).to_h["fields"].to_a
  end
end
