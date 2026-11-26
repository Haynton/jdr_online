module Settings
  # Saves the interface language without the current password: unlike the email or the password,
  # it protects nothing. The display section sends it as soon as the list changes, and so does the window of the
  # settings of the game room (game_table_id), which gets its room back, the window open on its display
  class LocalesController < ApplicationController
    def update
      return redirect_to(page_after_update, alert: t(".unavailable")) unless current_user.update(locale_params)

      # The page that follows, and this message, are already in the new language. The page itself shows the change:
      # the message is for screen readers only
      I18n.locale = chosen_locale
      redirect_to page_after_update, flash: { screen_reader_notice: t(".updated") }
    end

    private

    def locale_params
      params.expect(user: [:locale])
    end

    # Only a table of the user: an id of another table is a page of the settings, like no id
    def page_after_update
      game_table = current_user.game_tables.find_by(id: params[:game_table_id]) if params[:game_table_id].present?
      game_table ? game_table_path(game_table, settings: "display") : settings_display_path
    end
  end
end
