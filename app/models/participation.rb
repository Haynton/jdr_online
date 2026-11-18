class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :game_table

  # Available roles
  enum :role, {
    game_master: "game_master",
    player: "player"
  }

  # Validations
  validates :role, presence: true

  # Only one game master per game table
  validates :game_table_id,
            uniqueness: {
              conditions: -> { where(role: "game_master") },
              message: "already has a game master"
            },
            if: :game_master?
end
