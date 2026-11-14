require "test_helper"

# Every key must exist in both languages: a page that is never opened in a test
# would otherwise hide a missing translation.
class LocaleFilesTest < ActiveSupport::TestCase
  test "french and english files define the same keys" do
    assert_equal translation_keys("en"), translation_keys("fr")
  end

  private

  def translation_keys(locale)
    translations = YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale)
    flatten_keys(translations).sort
  end

  def flatten_keys(translations, parent_key = nil)
    translations.flat_map do |key, value|
      full_key = [parent_key, key].compact.join(".")
      value.is_a?(Hash) ? flatten_keys(value, full_key) : full_key
    end
  end
end
