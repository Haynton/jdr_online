# What a user knows of their friends (Settings › Friends): the friend requests they sent and received,
# and the friends who accepted, whoever asked first
module HasFriends
  extend ActiveSupport::Concern

  included do
    has_many :sent_friendships, class_name: "Friendship", foreign_key: :requester_id,
                                inverse_of: :requester, dependent: :destroy
    has_many :received_friendships, class_name: "Friendship", foreign_key: :addressee_id,
                                    inverse_of: :addressee, dependent: :destroy
  end

  def friendships
    Friendship.involving(self)
  end

  # Subqueries, not lists loaded in Ruby: the friends are read in the same query as what uses them
  def friends
    User.where(id: sent_friendships.accepted.select(:addressee_id))
        .or(User.where(id: received_friendships.accepted.select(:requester_id)))
  end

  # Sorted by the username of the friend, whoever asked: read in Ruby, the friend being on either side
  def accepted_friendships
    friendships.accepted
               .includes(requester: { avatar_attachment: :blob }, addressee: { avatar_attachment: :blob })
               .sort_by { |friendship| friendship.friend_of(self).username.downcase }
  end

  def friend_requests_received
    received_friendships.pending.includes(requester: { avatar_attachment: :blob }).order(created_at: :desc)
  end

  def friend_requests_sent
    sent_friendships.pending.includes(addressee: { avatar_attachment: :blob }).order(created_at: :desc)
  end

  def friend?(other_user)
    Friendship.accepted.between(self, other_user).exists?
  end
end
