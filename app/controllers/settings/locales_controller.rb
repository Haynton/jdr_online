module Settings
  # Saves the interface language without the current password: unlike the email or the password,
  # it protects nothing. The display section sends it as soon as the list changes
  class LocalesController < ApplicationController
    def update
      return redirect_to(settings_display_path, alert: t(".unavailable")) unless current_user.update(locale_params)

      # The page that follows, and this message, are already in the new language
      I18n.locale = chosen_locale
      redirect_to settings_display_path, notice: t(".updated")
    end

    private

    def locale_params
      params.expect(user: [:locale])
    end
  end
end
