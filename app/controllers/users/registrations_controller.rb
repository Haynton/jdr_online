module Users
  class RegistrationsController < Devise::RegistrationsController
    include DeviseLocale

    # The old account page (/users/edit) and its form are replaced by the settings:
    # the language in Display, the email and the account deletion in Account, the password in Security
    def edit
      redirect_to settings_account_path
    end

    # Nothing is changed here: an old form or bookmark lands on the account settings
    def update
      redirect_to settings_account_path
    end

    protected

    # Only the browser language is stored: a user without one keeps following the default locale
    def build_resource(hash = {})
      super
      resource.locale ||= locale_from_browser
    end
  end
end
