class GameTable < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60
  # The images of app/assets/images/covers. The default one is also the default of the column
  COVER_IMAGES = %w[sentinelle citadelle dragon gobelins village wolf].freeze
  DEFAULT_COVER_IMAGE = "sentinelle".freeze

  has_many :participations, dependent: :destroy
  has_many :users, through: :participations

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :cover_image, inclusion: { in: COVER_IMAGES }

  def self.cover_image_path(cover_image)
    "covers/#{cover_image}.webp"
  end

  def cover_image_path
    self.class.cover_image_path(cover_image)
  end

  # Read in Ruby: "My tables" loads the participations of every table at once, without a query per card
  def players
    participations.select(&:player?).map(&:user)
  end

  def players_count
    participations.count(&:player?)
  end
end
