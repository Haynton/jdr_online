require "test_helper"

class BrowserLocaleDetectorTest < ActiveSupport::TestCase
  test "returns the preferred language when it is available" do
    assert_equal "fr", detect("fr-FR,fr;q=0.9,en;q=0.8")
  end

  test "skips unavailable languages to reach an available preference" do
    assert_equal "en", detect("de-DE,de;q=0.9,en;q=0.8")
  end

  test "returns nil when no browser language is available" do
    assert_nil detect("de-DE,es;q=0.8")
  end

  test "returns nil for a missing header" do
    assert_nil detect(nil)
  end

  private

  def detect(accept_language_header)
    Locales::BrowserLocaleDetector.new(accept_language_header).call
  end
end
