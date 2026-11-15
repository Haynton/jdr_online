require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  test "the settings open on the display section" do
    sign_in create_user(locale: "fr")
    get settings_path

    assert_redirected_to settings_display_path
  end

  test "the display section shows the panel, its section menu and its title" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_response :success
    assert_select "nav[aria-labelledby=settings-title] h1", text: "Paramètres"
    assert_select "nav[aria-labelledby=settings-title] a[href=?][aria-current=page]", settings_display_path,
                  text: "Affichage"
    assert_select "nav[aria-labelledby=settings-title] a[href=?]", edit_user_registration_path, text: "Compte"
    assert_select "section[aria-labelledby=settings-section-title] h2", text: "Affichage"
  end

  test "the theme row offers the three choices, named by the row label" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_select "h3", text: "Thème"
    assert_select "p#theme-setting", text: "Thème"
    assert_select "[role=group][aria-labelledby=theme-setting][data-controller=theme] button", count: 3
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
    assert_select "[role=status]", text: "Language saved."
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

  test "the settings are translated in english" do
    sign_in create_user(locale: "en")
    get settings_display_path

    assert_select "h1", text: "Settings"
    assert_select "h2", text: "Display"
  end

  test "settings is the current link of the account menu" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "a visitor is sent to the sign in page" do
    get settings_display_path

    assert_redirected_to new_user_session_path
  end

  private

  def create_user(locale:)
    User.create!(email: "player@example.com", password: TEST_PASSWORD, locale: locale)
  end
end
