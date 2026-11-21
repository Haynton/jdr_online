class GameTable < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # The images of app/assets/images/covers. The default one is also the default of the column
  COVER_IMAGES = %w[sentinelle citadelle dragon gobelins village wolf].freeze
  DEFAULT_COVER_IMAGE = "sentinelle".freeze
  # Default of the status column: the table is not fully set up yet. Any other status counts as in progress
  # (decision: the exact list of statuses comes with the creation form)
  DRAFT_STATUS = "draft".freeze
  # The steps of the creation, in order: creation_step holds the number of the step reached (1 for "details").
  CREATION_STEPS = %w[details npcs maps invitations summary].freeze
  # They come with their milestone (P4, P3): shown as coming soon until then, and skipped by the creation
  LATER_CREATION_STEPS = %w[npcs maps].freeze

  # The template the table was made from, for information only: the table plays with template_snapshot
  belongs_to :sheet_template, optional: true
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :cover_image, inclusion: { in: COVER_IMAGES }
  # Asked on the first step of the creation (save(context: :details)), not for the tables made before it
  validates :sheet_template, presence: true, on: :details

  # The table plays with a frozen copy of its template: changing it while the table is a draft copies it again
  def use_sheet_template(sheet_template)
    self.sheet_template = sheet_template
    self.template_snapshot = sheet_template ? sheet_template.snapshot : {}
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

  # Read in Ruby: "My tables" loads the participations of every table at once, without a query per card
  def players
    participations.select(&:player?).map(&:user)
  end

  def players_count
    participations.count(&:player?)
  end
end
