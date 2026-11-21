# The game master invites a player to their table by the player's username (summary of the creation).
# Not a table of its own: saving it makes a pending participation, which the player accepts or refuses later.
# A form object, so that Simple Form shows its errors under the field like any other
class PlayerInvitation
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :username, :string

  attr_reader :game_table, :participation

  validates :username, presence: true
  validate :invited_user_exists
  validate :invited_user_not_at_table

  def initialize(game_table:, **attributes)
    @game_table = game_table
    super(**attributes)
  end

  def save
    return false unless valid?

    @participation = game_table.participations.create!(user: invited_user, role: :player, status: :pending)
  end

  # The username as the player wrote it, whatever the case typed by the game master
  def invited_username
    invited_user&.username
  end

  private

  # Usernames are unique whatever their case (index on lower(username))
  def invited_user
    return if username.blank?

    @invited_user ||= User.find_by("lower(username) = ?", username.strip.downcase)
  end

  def invited_user_exists
    errors.add(:username, :not_found) if username.present? && invited_user.nil?
  end

  # Covers the game master too, who is at the table already
  def invited_user_not_at_table
    return unless invited_user && game_table.participations.exists?(user: invited_user)

    errors.add(:username, :already_at_table)
  end
end
