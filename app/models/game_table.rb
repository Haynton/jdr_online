class GameTable < ApplicationRecord
  include TemplateCopy

  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # The images of app/assets/images/covers (WebP, 1600 px wide), each with its theme, which filters them when a game
  # master picks one. The order is the one of the row. The default one is also the default of the column.
  # A new cover: its file, its line here, its label in game_tables.covers (fr.yml and en.yml)
  COVER_THEMES = {
    "sentinelle" => "fantasy", "citadelle" => "fantasy", "dragon" => "fantasy", "gobelins" => "fantasy",
    "village" => "fantasy", "hobbit" => "fantasy", "wolf" => "fantasy",
    "lovecraft" => "horror",
    "cyberpunk" => "science_fiction", "metropole" => "science_fiction"
  }.freeze
  COVER_IMAGES = COVER_THEMES.keys.freeze
  # In the order of their pills
  COVER_THEME_NAMES = COVER_THEMES.values.uniq.freeze
  DEFAULT_COVER_IMAGE = "sentinelle".freeze
  # Default of the status column: the table is not fully set up yet. Any other status counts as in progress
  # (decision: the exact list of statuses comes with the creation form)
  DRAFT_STATUS = "draft".freeze
  # Set by the last step of the creation: players may join the table through its invitation link
  READY_STATUS = "ready".freeze
  # The steps of the creation, in order: creation_step holds the number of the step reached (1 for "details").
  # The invitation link sits in the summary (decision): it only works once the table is ready, which the summary does
  # Settings comes right after the choice of the template, since its settings depend on it (the starting level)
  # Then the catalog of the table (the spells and items offered), before its NPCs
  CREATION_STEPS = %w[details settings catalog npcs maps summary].freeze
  # They come with their milestone (P4, P3): shown as coming soon until then, and skipped by the creation
  LATER_CREATION_STEPS = %w[npcs maps].freeze
  AVAILABLE_CREATION_STEPS = (CREATION_STEPS - LATER_CREATION_STEPS).freeze
  # The level of the characters when the game begins, chosen by the game master. Same bounds as in the database
  STARTING_LEVELS = (1..20)

  # The secret part of the invitation link, given to each new table. Regenerating it disables the old link
  has_secure_token :invite_token

  # The template the table was made from, for information only: the table plays with template_snapshot
  belongs_to :sheet_template, optional: true
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
  has_many :characters, dependent: :destroy
  # The NPCs and monsters of the game master, in the order they were added
  has_many :npcs, -> { of_game_master.order(:id) }, class_name: "Character", inverse_of: :game_table
  # Its own catalog entries: copies of entries of its template changed for it, entries added (Catalogs::TableCatalog)
  has_many :catalog_entries, dependent: :destroy

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :cover_image, inclusion: { in: COVER_IMAGES }
  validates :starting_level, inclusion: { in: STARTING_LEVELS }
  # Asked on the first step of the creation (save(context: :details)), not for the tables made before it
  validates :sheet_template, presence: true, on: :details

  # The table plays with a frozen copy of its template: changing it while the table is a draft copies it again
  def use_sheet_template(sheet_template)
    self.sheet_template = sheet_template
    self.template_snapshot = sheet_template ? sheet_template.snapshot : {}
  end

  # The template makes its characters start at a level the table sets (a field from_table: "starting_level"): the
  # step Settings then asks it. A template without levels ("Cosmic horror") asks nothing there
  def asks_starting_level?
    character_sheet_fields.any? { |field| field["from_table"] == "starting_level" }
  end

  # The fields asked when a player makes their character: all but the states of the game (at_creation: false,
  # decision: the inspiration or the temporary hit points only change during the game) and the values given by the
  # table (from_table: the level, set by the game master)
  def character_creation_fields
    character_sheet_fields.reject { |field| field["at_creation"] == false || field["from_table"] }
  end

  # What a new character starts with, given by the table: the level of the field marked from_table
  def character_values_from_table
    character_sheet_fields.select { |field| field["from_table"] == "starting_level" }
                          .to_h { |field| [field["key"], starting_level] }
  end

  # The abilities of the character sheet (fields of the ability type), the ones the dice can roll
  def ability_fields
    character_sheet_fields.select { |field| field["type"] == "ability" }
  end

  # How the template rolls the abilities ({ "dice" => 4, "sides" => 6, "keep_highest" => 3 }), or nil: no roll
  def ability_roll_method
    return nil if ability_fields.empty?

    template_snapshot.to_h.dig("character_fields", "ability_roll")
  end

  # Players join through the invitation link once the creation is over
  def joinable?
    !draft?
  end

  def self.cover_image_path(cover_image)
    "covers/#{cover_image}.webp"
  end

  def cover_image_path
    self.class.cover_image_path(cover_image)
  end

  def draft?
    status == DRAFT_STATUS
  end

  # The step that comes after this one, skipping the steps of a later milestone
  def self.next_creation_step(step)
    AVAILABLE_CREATION_STEPS[AVAILABLE_CREATION_STEPS.index(step) + 1]
  end

  # Where "Resume the creation" leads: the step reached, or the last one before it that exists already
  def resume_creation_step
    reached_steps = CREATION_STEPS.first(creation_step.to_i.clamp(1, CREATION_STEPS.size))
    (reached_steps & AVAILABLE_CREATION_STEPS).last
  end

  # Never goes back: taking up an earlier step again keeps the progress made
  def reach_creation_step(step)
    step_number = CREATION_STEPS.index(step) + 1
    update!(creation_step: step_number) if step_number > creation_step.to_i
  end

  # The last step: the table is ready, players may join it
  def finish_creation!
    update!(status: READY_STATUS, creation_step: CREATION_STEPS.size)
  end

  # Read in Ruby: "My tables" loads the participations of every table at once, without a query per card.
  # Only the players who accepted: a pending invitation does not count yet
  def players
    player_participations.select(&:accepted?).map(&:user)
  end

  def players_count
    player_participations.count(&:accepted?)
  end

  # Read in Ruby, like the players: who sent the invitations of the table
  def game_master
    participations.detect(&:game_master?)&.user
  end

  # Every invited player, pending or accepted, in the order they were invited (summary of the creation)
  def player_participations
    participations.select(&:player?).sort_by(&:created_at)
  end
end
