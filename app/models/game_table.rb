class GameTable < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60

  has_many :participations, dependent: :destroy
  has_many :users, through: :participations

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
end
