class User < ApplicationRecord
  has_many :participations, dependent: :destroy
  # Only the tables the user takes part in: an invitation still pending does not open a table
  has_many :game_tables, -> { merge(Participation.accepted) }, through: :participations
  has_many :sheet_templates, foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy

  USERNAME_LENGTH = 3..20
  # Letters (accents included), digits, dash and underscore: no space, so it reads the same everywhere
  USERNAME_FORMAT = /\A[[:alnum:]_-]*\z/

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # A blank locale means "no choice yet": store it as nil so there is only one way to say it
  normalizes :locale, with: lambda(&:presence)
  normalizes :username, with: lambda(&:strip)

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, allow_nil: true
  # allow_blank on the length: an empty username only gets the "can't be blank" message
  validates :username, presence: true,
                       length: { in: USERNAME_LENGTH, allow_blank: true },
                       format: { with: USERNAME_FORMAT },
                       uniqueness: { case_sensitive: false }

  # The usernames that begin with what was typed, whatever the case (suggestions when inviting a player).
  # sanitize_sql_like: a % or _ typed stays a plain character, not a wildcard
  scope :username_starting_with, lambda { |typed_text|
    where("lower(username) LIKE ?", "#{sanitize_sql_like(typed_text.downcase)}%")
  }

  # Shown in the avatar
  def initials
    username.to_s.scan(/[[:alnum:]]/).first(2).join.upcase
  end
end
