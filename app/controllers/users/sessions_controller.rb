module Users
  class SessionsController < Devise::SessionsController
    include DeviseLocale
    include ScreenReaderNotice

    protected

    # The locale is chosen before Devise finds the user, so it comes from the browser.
    # The message uses the signed-in user's language instead; on sign out there is no user
    # any more, so it follows the browser, like the page that displays it.
    # "Signed in." and "Signed out." only repeat what the page shows (the user's tables, or the home page
    # with its sign in link): for screen readers only
    def set_flash_message!(key, kind, options = {})
      I18n.with_locale(chosen_locale(resource)) { super }
      keep_for_screen_readers_only if kind.in?(%i[signed_in signed_out])
    end
  end
end
