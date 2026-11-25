module Settings
  # Usernames suggested while the user types the one of a friend to add (username_suggestions_controller.js):
  # never the user, nor somebody already a friend or already asked, either way
  class FriendSuggestionsController < ApplicationController
    def index
      render json: UsernameSuggester.new(typed_text: params[:query], excluded_users: excluded_user_ids).call
    end

    private

    def excluded_user_ids
      [current_user.id] + current_user.friendships.pluck(:requester_id, :addressee_id).flatten
    end
  end
end
