# A character sheet template: the fields of the character sheet, of the NPC and monster sheet and of the items,
# plus ready-made NPCs, monsters and items. Its content is JSONB (see "Base de données", the design notes):
# the game master invents the fields. A game table never plays with it directly, but with a frozen copy (snapshot)
class SheetTemplate < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # What a game table copies when it picks this template. The ready-made NPCs and monsters are not in it:
  # they become rows of their own, which the game master can change (characters, later)
  SNAPSHOT_ATTRIBUTES = %w[character_fields npc_fields item_fields rest_rules level_thresholds preset_items].freeze
  # The closed list of field types: a type is a behavior the app knows how to show and check, not a game, and it has
  # one look wherever it is on the sheet (decision, for the template builder: the game master picks a type, names it).
  # ability: a score with a modifier worked out by its rule (modifier, one of MODIFIER_RULES).
  # attacks: a list of attacks (name, to hit, damage, range), for NPCs and monsters.
  # bonus: the modifier of an ability (based_on), plus a proficiency (proficiency, the key of a computed field) when
  # the player ticks it: the sheet only stores the tick (CharacterSheetCalculator).
  # computed: a value the sheet never stores, worked out by one of the COMPUTED_RULES
  FIELD_TYPES = %w[number resource ability boolean text choice experience attacks bonus computed].freeze
  # How the modifier of an ability is worked out. half_above_ten: (score - 10) / 2, rounded down (14 gives +2)
  MODIFIER_RULES = %w[half_above_ten].freeze
  # The game master picks a rule, never writes a formula (design notes, "Règles de jeu : choisies dans une liste").
  # proficiency_by_level: the proficiency_bonus, in level_thresholds, of the level typed in the field level_from.
  # ability_modifier: the modifier of the ability in based_on (initiative). Both read as a bonus (+2, -1).
  # hit_dice_by_class: one die per level (level_from), its sides the hit_die of the class chosen (class_from): "3d8"
  COMPUTED_RULES = %w[proficiency_by_level ability_modifier hit_dice_by_class].freeze
  # What choosing an option of a list does to the sheet (effects of a choice field, by option), from this closed
  # list. Only an aid: the player can still tick or untick anything (decision).
  # hit_die: the sides of the hit dice (hit_dice_by_class). proficient: the bonus fields ticked (saving throws),
  # unticked when another option is chosen. skill_choices: how many bonus fields to pick (count) among a list (from)
  CHOICE_EFFECTS = %w[hit_die proficient skill_choices].freeze

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :parent, class_name: "SheetTemplate", optional: true
  has_many :derived_templates, class_name: "SheetTemplate", foreign_key: :parent_id,
                               inverse_of: :parent, dependent: :nullify
  has_many :game_tables, dependent: :nullify

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
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
