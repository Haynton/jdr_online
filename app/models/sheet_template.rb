# A character sheet template: the fields of the character sheet, of the NPC and monster sheet and of the items,
# plus ready-made NPCs, monsters and items. Its content is JSONB (see "Base de données", the design notes):
# the game master invents the fields. A game table never plays with it directly, but with a frozen copy (snapshot)
class SheetTemplate < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # What a game table copies when it picks this template. The ready-made NPCs and monsters are not in it:
  # they become rows of their own, which the game master can change (characters, later)
  SNAPSHOT_ATTRIBUTES = %w[character_fields npc_fields item_fields rest_rules level_thresholds preset_items].freeze
  # The closed list of field types: a type is a behavior the app knows how to show and check, not a game.
  # attacks: a list of attacks (name, to hit, damage, range), for NPCs and monsters
  FIELD_TYPES = %w[number resource boolean text choice experience attacks].freeze

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
