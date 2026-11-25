module Settings
  # Asks a user to be friends (create), accepts a request received (update), refuses or cancels a request,
  # or removes a friend (destroy). Only the friendships of the user: 404 otherwise.
  # The section shows the result already: the messages are for screen readers only
  class FriendshipsController < BaseController
    include FriendsSection

    def create
      friend_request = FriendRequest.new(requester: current_user, username: params.dig(:friend_request, :username))
      return redirect_to_friends(created_message(friend_request)) if friend_request.save

      prepare_friends_section(friend_request)
      render "settings/friends/show", status: :unprocessable_content
    end

    # Only the user asked may accept
    def update
      friendship = current_user.received_friendships.pending.find(params[:id])
      friendship.accepted!
      redirect_to_friends(t(".accepted", username: friendship.requester.username))
    end

    def destroy
      friendship = current_user.friendships.find(params[:id])
      friendship.destroy!
      redirect_to_friends(t(".#{removal_kind(friendship)}", username: friendship.friend_of(current_user).username))
    end

    private

    def redirect_to_friends(message)
      redirect_to settings_friends_path, flash: { screen_reader_notice: message }
    end

    def created_message(friend_request)
      key = friend_request.accepted_existing_request? ? ".accepted" : ".sent"
      t(key, username: friend_request.asked_username)
    end

    def removal_kind(friendship)
      return :removed if friendship.accepted?

      friendship.requester == current_user ? :cancelled : :refused
    end
  end
end
