require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  test "a signed-in user sees the language of their account" do
    sign_in create_user(locale: "fr")

    get game_tables_path

    assert_page_language "fr"
  end

  test "a visitor sees the language of their browser" do
    get root_path, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }

    assert_page_language "fr"
  end

  test "a visitor with an unavailable browser language sees english" do
    get root_path, headers: { "Accept-Language" => "de" }

    assert_page_language "en"
  end

  test "a visitor without a browser language sees english" do
    get root_path

    assert_page_language "en"
  end

  test "the account language wins over the browser language" do
    sign_in create_user(locale: "en")

    get game_tables_path, headers: { "Accept-Language" => "fr" }

    assert_page_language "en"
  end

  private

  def create_user(locale:)
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: locale)
  end

  def assert_page_language(expected_locale)
    assert_response :success
    assert_select "html[lang=?]", expected_locale
  end
end

# The default locale is switched to french here so that getting english
# can only come from the browser preference, not from the fallback.
class LocaleWithFrenchDefaultTest < ActionDispatch::IntegrationTest
  setup do
    @original_default_locale = I18n.default_locale
    I18n.default_locale = :fr
  end

  # The request saves the french default as the current locale once it is over (I18n.with_locale puts back the locale
  # it found), and it would stay for the tests that follow: their messages would be in french
  teardown do
    I18n.default_locale = @original_default_locale
    I18n.locale = @original_default_locale
  end

  test "a less preferred available language beats the default locale" do
    get root_path, headers: { "Accept-Language" => "de-DE,de;q=0.9,en;q=0.8" }

    assert_response :success
    assert_select "html[lang=?]", "en"
  end
end
