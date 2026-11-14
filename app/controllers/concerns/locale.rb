module Locale
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&)
    I18n.with_locale(chosen_locale, &)
  end

  # The account choice wins so a user keeps their language on every device
  def chosen_locale(user = current_user)
    locale_from_user(user) || locale_from_browser || I18n.default_locale
  end

  def locale_from_user(user)
    available_locale(user&.locale)
  end

  def locale_from_browser
    BrowserLocaleDetector.new(request.headers["Accept-Language"]).call
  end

  def available_locale(candidate_locale)
    candidate_locale if I18n.available_locales.map(&:to_s).include?(candidate_locale.to_s)
  end
end
