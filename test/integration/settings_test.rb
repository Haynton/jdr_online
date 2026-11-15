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
