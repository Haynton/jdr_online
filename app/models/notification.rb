# Something that waits for an answer from the user, shown in the window of the bell (NotificationsController):
# a friend request received, an invitation to a table that is ready. Not a table of its own: read from
# the friendships and the participations, so that answering one anywhere (Settings › Friends, "My tables")
# removes it from the bell too. Most recent first
class Notification
  # One partial per kind, written in full (a partial named by a built string would not be found by a search)
  PARTIALS = {
    friend_request: "notifications/friend_request",
    table_invitation: "notifications/table_invitation"
  }.freeze

  attr_reader :kind, :source, :received_at

  def self.for(user)
    (friend_requests_of(user) + table_invitations_of(user)).sort_by(&:received_at).reverse
  end

  # Counted on every page, for the dot of the bell: two counts, nothing loaded
  def self.count_for(user)
    user.received_friendships.pending.count + user.participations.invitations_to_ready_tables.count
  end

  def self.friend_requests_of(user)
    user.friend_requests_received.map { |friendship| new(:friend_request, friendship) }
  end

  def self.table_invitations_of(user)
    user.participations.invitations_to_ready_tables
        .includes(game_table: { participations: { user: { avatar_attachment: :blob } } })
        .map { |participation| new(:table_invitation, participation) }
  end

  def initialize(kind, source)
    @kind = kind
    @source = source
    @received_at = source.created_at
  end

  def partial
    PARTIALS.fetch(kind)
  end
end
