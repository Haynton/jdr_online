# Usernames suggested while a user types the one of somebody else (a player to invite, a friend to add):
# a few, beginning with what was typed, never the excluded users.
# With friends_first_of, the friends of that user come first, and are suggested before anything is typed
# (they are few, and the most likely to be invited); the other users only from MINIMUM_TYPED_LENGTH letters
class UsernameSuggester
  # Below two letters, almost every user would match
  MINIMUM_TYPED_LENGTH = 2
  SUGGESTIONS_LIMIT = 8

  def initialize(typed_text:, excluded_users:, friends_first_of: nil)
    @typed_text = typed_text.to_s.strip
    @excluded_users = excluded_users
    @friends_first_of = friends_first_of
  end

  def call
    (friend_usernames + other_usernames).uniq.first(SUGGESTIONS_LIMIT)
  end

  private

  def friend_usernames
    return [] unless @friends_first_of

    usernames_among(@friends_first_of.friends)
  end

  def other_usernames
    return [] if @typed_text.length < MINIMUM_TYPED_LENGTH

    usernames_among(User.all)
  end

  def usernames_among(users)
    users.username_starting_with(@typed_text).where.not(id: @excluded_users)
         .order(:username).limit(SUGGESTIONS_LIMIT).pluck(:username)
  end
end
