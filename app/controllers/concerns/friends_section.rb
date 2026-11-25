# What the friends section of the settings shows, for its page and when its form comes back with an error
module FriendsSection
  extend ActiveSupport::Concern

  private

  def prepare_friends_section(friend_request)
    @friend_request = friend_request
    @friend_requests_received = current_user.friend_requests_received
    @friend_requests_sent = current_user.friend_requests_sent
    @friendships = current_user.accepted_friendships
  end
end
