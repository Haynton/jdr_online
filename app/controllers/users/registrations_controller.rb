module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    # Only the browser language is stored: a user without one keeps following the default locale
    def build_resource(hash = {})
      super
      resource.locale ||= locale_from_browser
    end
  end
end
