module Locales
  class Locales::BrowserLocaleDetector
    def initialize(accept_language_header)
      @accept_language_header = accept_language_header
    end

    def call
      browser_languages.find { |language| available_locales.include?(language) }
    end

    private

    def browser_languages
      Locales::AcceptLanguageParser.new(@accept_language_header).call
    end

    def available_locales
      I18n.available_locales.map(&:to_s)
    end
  end
end
