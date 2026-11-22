# A character sheet template: the fields of the character sheet, of the NPC and monster sheet, of the items and of
# the spells, plus ready-made NPCs, monsters and items, and its catalog (catalog_entries: spells for now). Its
# content is JSONB (see "Base de données", the design notes): the game master invents the fields. A game table never
# plays with it directly, but with a frozen copy (snapshot)
class SheetTemplate < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # What a game table copies when it picks this template. The ready-made NPCs and monsters are not in it:
  # they become rows of their own, which the game master can change (characters, later)
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
  # list. Only an aid: the player can still change anything (decision); another option replaces the effects.
  # Applied on the sheet: hit_die (the sides of the hit dice, hit_dice_by_class); proficient (the bonus fields
  # ticked: saving throws of a class, skills of a background); skill_choices (how many bonus fields to pick, count,
  # among a list, from); set (values written in fields: the speed and size of a species); spellcasting (ability,
  # then by level from 1 to 20: cantrips, prepared spells, highest spell level).
  # Kept for the creation steps, by key of the future catalog: ability_bonus_choices (the 3 abilities a background
  # raises: +2 and +1, or +1 to each), training (armour and weapons), tools, features_by_level, traits, origin_feat
  # unarmored_defense: the ability whose modifier adds to the armour class without armour (unarmored_armor_class).
  # starting_equipment: the options of the starting equipment (CharacterSheets::StartingEquipment), picked in an
  # equipment_option field
  CHOICE_EFFECTS = %w[
    hit_die proficient skill_choices set spellcasting unarmored_defense
    ability_bonus_choices training tools features_by_level traits origin_feat starting_equipment
  ].freeze

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :parent, class_name: "SheetTemplate", optional: true
  has_many :derived_templates, class_name: "SheetTemplate", foreign_key: :parent_id,
                               inverse_of: :parent, dependent: :nullify
  has_many :game_tables, dependent: :nullify
  # Its spells, items... (one shared table, decision). Deleted with it for now: a template still used by a table will be
  # archived rather than deleted, with the template builder (its tables read its catalog)
  has_many :catalog_entries, dependent: :destroy

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
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

  def snapshot
    attributes.slice(*SNAPSHOT_ATTRIBUTES)
  end
end
