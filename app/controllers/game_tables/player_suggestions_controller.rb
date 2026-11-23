# Usernames suggested while the game master types the one of a player to invite (summary of the creation),
# read by username_suggestions_controller.js. A few, beginning with what was typed, never someone already at the table
module GameTables
  class PlayerSuggestionsController < ApplicationController
    include TableOfGameMaster

    # Below two letters, almost every player would match
    MINIMUM_TYPED_LENGTH = 2
    SUGGESTIONS_LIMIT = 8

    def index
      render json: suggested_usernames
    end

    private

    def suggested_usernames
      typed_text = params[:query].to_s.strip
      return [] if typed_text.length < MINIMUM_TYPED_LENGTH

      User.username_starting_with(typed_text)
          .where.not(id: @game_table.participations.select(:user_id))
          .order(:username).limit(SUGGESTIONS_LIMIT).pluck(:username)
    end
  end
end
