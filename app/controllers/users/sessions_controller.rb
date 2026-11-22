module Users
  class SessionsController < Devise::SessionsController
    include DeviseLocale
    include ScreenReaderNotice

    protected

    # The locale is chosen before Devise finds the user, so it comes from the browser.
    # The message uses the signed-in user's language instead; on sign out there is no user
    # any more, so it follows the browser, like the page that displays it
    def set_flash_message!(key, kind, options = {})
      I18n.with_locale(chosen_locale(resource)) { super }
    end
  end
end
