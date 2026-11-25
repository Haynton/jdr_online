module Settings
  # Friends section of the settings: add a friend by their username, answer the requests received,
  # see the requests sent, and the friends
  class FriendsController < BaseController
    include FriendsSection

    def show
      prepare_friends_section(FriendRequest.new(requester: current_user))
    end
  end
end
