require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  test "on a phone, /settings shows the list of sections; on a wide screen, the display section next to it" do
    sign_in create_user(locale: "fr")
    get settings_path

    assert_response :success
    assert_select "nav[aria-labelledby=settings-title]:not(.hidden)"
    assert_select "main.hidden.md\\:block h2", text: "Affichage"
    assert_select "nav a[href=?][aria-current=page]", settings_display_path, text: "Affichage"
  end

  test "on a phone, a section page shows its section and a way back to the list" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_select "nav.hidden.md\\:block[aria-labelledby=settings-title]"
    assert_select "main:not(.hidden) a.md\\:hidden[href=?]", settings_path, text: "Paramètres"
  end

  test "each section of the list has a chevron, shown on a phone only" do
    sign_in create_user(locale: "fr")
    get settings_path

    assert_select "nav li a svg.md\\:hidden[aria-hidden=true]", count: 5
  end

  test "each setting row has a line under it, the last one of a group included" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_select "section h3 + div > div.border-b.border-line", count: 2
  end

  test "the display section shows the panel, its section menu and its title" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_response :success
    assert_select "nav[aria-labelledby=settings-title] h1", text: "Paramètres"
    assert_select "nav[aria-labelledby=settings-title] a[href=?][aria-current=page]", settings_display_path,
                  text: "Affichage"
    assert_select "nav[aria-labelledby=settings-title] a[href=?]", settings_account_path, text: "Compte"
    assert_select "section[aria-labelledby=settings-section-title] h2", text: "Affichage"
  end

  test "the settings are centered, the section menu on the page and the section in a card" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_select "div.mx-auto.max-w-\\[1120px\\].md\\:grid" do
      assert_select "nav[aria-labelledby=settings-title] + main"
    end
    assert_select "main section.rounded-xl.border-line.bg-surface[aria-labelledby=settings-section-title]"
  end

  test "the theme row offers the three choices, named by the row label" do
    sign_in create_user(locale: "fr")
    get settings_display_path

    assert_select "h3", text: "Thème"
    assert_select "p#theme-setting", text: "Thème"
    assert_select "[role=group][aria-labelledby=theme-setting][data-controller=theme] button", count: 3
    assert_select "[role=group][aria-labelledby=theme-setting] button:not([title]) svg + span:not(.sr-only)",
                  text: "Clair"
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

    assert_select "#side-nav div.hidden.md\\:flex a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "a visitor is sent to the sign in page" do
    get settings_display_path

    assert_redirected_to new_user_session_path
  end

  private

  def create_user(locale:)
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: locale)
  end
end
