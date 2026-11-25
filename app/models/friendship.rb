# Two users who are friends, or one who asked the other. One row per pair, whoever asked (unique index on the pair):
# pending until the addressee accepts. Refusing, cancelling or removing a friend deletes the row,
# so that either of them may ask again later
class Friendship < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :addressee, class_name: "User"

  enum :status, {
    pending: "pending",
    accepted: "accepted"
  }

  # The friendships a user takes part in, on either side
  scope :involving, ->(user) { where(requester: user).or(where(addressee: user)) }
  scope :between, lambda { |user, other_user|
    where(requester: user, addressee: other_user).or(where(requester: other_user, addressee: user))
  }

  validate :not_with_oneself
  validate :one_per_pair, on: :create

  # The other user of the pair, seen from one of them
  def friend_of(user)
    requester_id == user.id ? addressee : requester
  end

  private

  def not_with_oneself
    errors.add(:addressee, :oneself) if requester_id.present? && requester_id == addressee_id
  end

  def one_per_pair
    errors.add(:addressee, :taken) if Friendship.between(requester, addressee).exists?
  end
end
