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

  # The invitations a player can answer: an invitation to a draft waits until the game master
  # has finished setting up the table (decision, same rule as the invitation link)
  scope :invitations_to_ready_tables, lambda {
    joins(:game_table).pending.where.not(game_tables: { status: GameTable::DRAFT_STATUS })
  }
  # "My tables": the tables of the user, and the invitations they have not answered yet
  scope :shown_in_my_tables, -> { joins(:game_table).accepted.or(invitations_to_ready_tables) }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :game_table_id, message: :already_at_table }
  validates :game_table_id,
            uniqueness: { conditions: -> { game_master }, message: :game_master_taken },
            if: :game_master?
end
