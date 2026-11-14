module Users
  class FailureApp < Devise::FailureApp
    # Devise's own controllers check authentication before the Locale concern runs,
    # so the locale Devise hands over is still the default one: read the browser instead
    def i18n_locale
      BrowserLocaleDetector.new(request.headers["Accept-Language"]).call || I18n.default_locale
    end
  end
end
