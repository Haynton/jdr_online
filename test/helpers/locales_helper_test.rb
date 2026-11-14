require "test_helper"

class LocalesHelperTest < ActionView::TestCase
  test "lists every available locale named in its own language" do
    assert_equal [["Français", "fr"], ["English", "en"]], locale_options
  end

  test "names the locales the same way whatever the current language" do
    french_options = I18n.with_locale(:fr) { locale_options }
    english_options = I18n.with_locale(:en) { locale_options }

    assert_equal french_options, english_options
  end
end
