# A user asks another to be friends, by their username (Settings › Friends). Not a table of its own: saving it makes
# a pending friendship, which the other user accepts or refuses. When the other user had already asked,
# asking them back accepts their request: both want it.
# A form object, so that Simple Form shows its errors under the field like any other (like PlayerInvitation)
class FriendRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :username, :string

  attr_reader :requester, :friendship

  validates :username, presence: true
  validate :asked_user_exists
  validate :asked_user_not_oneself
  validate :not_already_asked

  def initialize(requester:, **attributes)
    @requester = requester
    super(**attributes)
  end

  def save
    return false unless valid?

    @friendship = request_from_asked_user
    return @friendship.tap(&:accepted!) if @friendship

    @friendship = requester.sent_friendships.create!(addressee: asked_user)
  end

  # Whether saving accepted a request the other user had sent: the message is not the same
  def accepted_existing_request?
    friendship&.accepted? && friendship.requester == asked_user
  end

  # The username as its owner wrote it, whatever the case typed
  def asked_username
    asked_user&.username
  end

  private

  # Usernames are unique whatever their case (index on lower(username))
  def asked_user
    return if username.blank?

    @asked_user ||= User.find_by("lower(username) = ?", username.strip.downcase)
  end

  def request_from_asked_user
    requester.received_friendships.pending.find_by(requester: asked_user)
  end

  def asked_user_exists
    errors.add(:username, :not_found) if username.present? && asked_user.nil?
  end

  def asked_user_not_oneself
    errors.add(:username, :oneself) if asked_user == requester
  end

  # Already friends, or already asked by the requester. A request received from them is not an error (see save)
  def not_already_asked
    return if asked_user.nil? || asked_user == requester
    return if request_from_asked_user

    existing = Friendship.between(requester, asked_user).first
    errors.add(:username, existing.accepted? ? :already_friends : :already_asked) if existing
  end
end
