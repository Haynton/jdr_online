require "test_helper"

class SettingsLanguageTest < ActionDispatch::IntegrationTest
  test "the confirmation message is for screen readers only: the page already shows the new language" do
    sign_in create_user(locale: "fr")
    patch settings_locale_path, params: { user: { locale: "en" } }
    follow_redirect!

    assert_select "#{section_card_selector} > header + div .sr-only [role=status]", text: "Language saved."
  end

  test "the language row offers the browser language and each language, named by the row label" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_select "form[action=?][data-controller=auto-submit]", settings_locale_path do
      assert_select "select#user_locale[aria-labelledby=language-setting] option", count: 3
      assert_select "select#user_locale option[value='']", text: "Langue du navigateur"
      assert_select "select#user_locale option[selected][value=fr]"
      assert_select "input[type=submit]", count: 0
    end
  end

  test "the language is saved without the password, and confirmed in the new language" do
    user = create_user(locale: "fr")
    sign_in user
    patch settings_locale_path, params: { user: { locale: "en" } }

    assert_equal "en", user.reload.locale
    assert_redirected_to settings_display_path
    follow_redirect!
    assert_select "html[lang=en]"
    assert_select ".sr-only [role=status]", text: "Language saved."
  end

  test "choosing the browser language clears the saved language" do
    user = create_user(locale: "fr")
    sign_in user
    patch settings_locale_path, params: { user: { locale: "" } }

    assert_nil user.reload.locale
  end

  test "an unavailable language is refused" do
    user = create_user(locale: "fr")
    sign_in user
    patch settings_locale_path, params: { user: { locale: "de" } }

    assert_equal "fr", user.reload.locale
    follow_redirect!
    assert_select "[role=alert]", text: "Cette langue n'est pas disponible."
  end

  test "only the language can be changed this way" do
    user = create_user(locale: "fr")
    sign_in user
    patch settings_locale_path, params: { user: { locale: "en", email: "someone.else@example.com" } }

    assert_equal "player@example.com", user.reload.email
  end

  private

  def section_card_selector
    "section[aria-labelledby=settings-section-title]"
  end

  def create_user(locale:)
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: locale)
  end
end
