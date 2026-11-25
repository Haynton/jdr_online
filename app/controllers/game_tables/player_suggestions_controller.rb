# Usernames suggested while the game master types the one of a player to invite (summary of the creation),
# read by username_suggestions_controller.js. Their friends first, never someone already at the table
module GameTables
  class PlayerSuggestionsController < ApplicationController
    include TableOfGameMaster

    def index
      render json: UsernameSuggester.new(typed_text: params[:query],
                                         excluded_users: @game_table.participations.select(:user_id),
                                         friends_first_of: current_user).call
    end
  end
end
