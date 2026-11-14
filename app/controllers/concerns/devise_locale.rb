# Devise controllers run their own checks with prepend_before_action, ahead of the Locale concern.
# Prepending the locale again from the subclass puts it back in front of those checks,
# so their messages ("You are already signed in.") use the user's language.
module DeviseLocale
  extend ActiveSupport::Concern

  included do
    prepend_around_action :switch_locale
  end
end
