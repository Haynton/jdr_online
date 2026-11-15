module Users
  class SessionsController < Devise::SessionsController
    include DeviseLocale

    protected

    # The locale is chosen before Devise finds the user, so it comes from the browser.
    # The message uses the signed-in user's language instead; on sign out there is no user
    # any more, so it follows the browser, like the page that displays it.
    def set_flash_message!(key, kind, options = {})
      I18n.with_locale(chosen_locale(resource)) { super }
      keep_for_screen_readers_only if kind == :signed_in
    end

    private

    # "Signed in." only repeats what the page already shows (the user's tables, the avatar):
    # hidden on screen, still read by screen readers (shared/_flashes)
    # Read, then delete: unlike a Hash, flash.delete returns the flash itself, not the message
    def keep_for_screen_readers_only
      flash[:screen_reader_notice] = flash[:notice]
      flash.delete(:notice)
    end
  end
end
