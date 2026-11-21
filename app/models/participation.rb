# Links a user to a game table, with their role there. The role lives here, not on the table,
# so that the game master of a table can change hands later
class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :game_table

  enum :role, {
    game_master: "game_master",
    player: "player"
  }

  # A player invited by their username is pending until they accept: the table is not theirs yet
  # ("My tables", players counted). The creator of a table and the players who joined are accepted
  enum :status, {
    accepted: "accepted",
    pending: "pending"
  }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :game_table_id, message: :already_at_table }
  validates :game_table_id,
            uniqueness: { conditions: -> { game_master }, message: :game_master_taken },
            if: :game_master?
end
