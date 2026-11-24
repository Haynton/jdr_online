# A character sheet template: the fields of the character sheet, of the NPC and monster sheet, of the items and of
# the spells, plus ready-made NPCs, monsters and items, and its catalog (catalog_entries: spells for now). Its
# content is JSONB (see "Base de données", the design notes): the game master invents the fields. A game table never
# plays with it directly, but with a frozen copy (snapshot)
class SheetTemplate < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # What the template is for, shown on its cards and in its banner (decision: 150 characters, 2 lines of its banner)
  DESCRIPTION_MAX_LENGTH = 150
  # The icons a template may show, by theme of the covers (GameTable::COVER_THEMES), the scroll by default: a closed
  # list, each a partial of shared/icons (SheetTemplatesHelper::ICON_PARTIALS)
  ICONS = {
    "fantasy" => %w[scroll_text swords castle crown shield wand_sparkles],
    "horror" => %w[flame skull ghost moon_star],
    "science_fiction" => %w[rocket bot]
  }.freeze
  ICON_NAMES = ICONS.values.flatten.freeze
  # The colors of its banner, gold by default: named colors of application.css (banner-*), drawn by
  # SheetTemplatesHelper::BANNER_CLASSES
  BANNER_COLORS = %w[gold crimson forest night arcane stone].freeze
  # What a game table copies when it picks this template. Its NPCs and monsters come from the bestiary of its catalog
  # (kind monster), each copied into the table as a character of its own by the game master
  SNAPSHOT_ATTRIBUTES = %w[
    character_fields npc_fields item_fields spell_fields rest_rules level_thresholds preset_items
  ].freeze
  # The closed list of field types: a type is a behavior the app knows how to type, check and show, not a game, and it
  # has one look wherever it is on the sheet (decision, for the template builder: the game master picks a type, names
  # it). Each one is a class of the registry, which says all about it (FieldTypes, app/models/field_types)
  FIELD_TYPES = FieldTypes.keys.freeze
  # How the modifier of an ability is worked out, and the rules of a computed field: closed lists, one class per rule
  # (ModifierRules, app/models/modifier_rules; ComputedRules, app/models/computed_rules)
  MODIFIER_RULES = ModifierRules.keys.freeze
  COMPUTED_RULES = ComputedRules.keys.freeze
  # What choosing an option of a list does to the sheet (effects of a choice field, by option), from this closed
  # list: one class per effect (ChoiceEffects, app/models/choice_effects)
  CHOICE_EFFECTS = ChoiceEffects.keys.freeze

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :parent, class_name: "SheetTemplate", optional: true
  has_many :derived_templates, class_name: "SheetTemplate", foreign_key: :parent_id,
                               inverse_of: :parent, dependent: :nullify
  has_many :game_tables, dependent: :nullify
  # Its spells, items... (one shared table, decision). Deleted with it for now: a template still used by a table will be
  # archived rather than deleted, with the template builder (its tables read its catalog)
  has_many :catalog_entries, dependent: :destroy

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }
  validates :icon, inclusion: { in: ICON_NAMES }
  validates :banner_color, inclusion: { in: BANNER_COLORS }
  # The template as a whole: its fields, the effects of its options, its steps (SheetTemplateValidator)
  validates_with SheetTemplateValidator
  # A predefined template is written in one of the languages of the app; a game master's template has no language
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, if: :predefined?
  validates :locale, absence: true, unless: :predefined?

  # Provided by the app (seed), for every game master
  scope :predefined, -> { where(owner_id: nil) }
  # The templates a user may pick for a table: the predefined ones in the language of the page, and their own
  scope :available_to, lambda { |user, locale: I18n.locale|
    predefined.where(locale: locale.to_s).or(where(owner_id: user.id))
  }

  def predefined?
    owner_id.nil?
  end

  # A table reads the catalog of its template (its spells, its items): a template still used is not deleted (it will
  # be archived, with the template editor)
  def used_by_tables?
    game_tables.exists?
  end

  def snapshot
    attributes.slice(*SNAPSHOT_ATTRIBUTES)
  end
end
