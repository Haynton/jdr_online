module Users
  class RegistrationsController < Devise::RegistrationsController
    include DeviseLocale

    before_action :permit_locale_on_account_update, only: :update

    protected

    # Only the browser language is stored: a user without one keeps following the default locale
    def build_resource(hash = {})
      super
      resource.locale ||= locale_from_browser
    end

    # Devise reloads the user into a new object and writes the "account updated" message
    # after this method: switching here shows that message in the newly chosen language
    def update_resource(resource, params)
      account_updated = super
      I18n.locale = chosen_locale(resource) if account_updated
      account_updated
    end

    private

    def permit_locale_on_account_update
      devise_parameter_sanitizer.permit(:account_update, keys: [:locale])
    end
  end
end
