class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # A blank locale means "no choice yet": store it as nil so there is only one way to say it
  normalizes :locale, with: lambda(&:presence)

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, allow_nil: true
end
