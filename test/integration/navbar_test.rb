require "test_helper"

class NavbarTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
  end

  test "a signed in user sees the logo and the account button, no other link" do
    get tables_path

    assert_select "nav[aria-label=?]", "Navigation principale" do
      assert_select "nav > a[href=?]", tables_path
      assert_select "button[aria-expanded=false][aria-controls=user-menu]"
    end
    assert_select "nav a", count: 3, message: "only the logo and the two links of the menu"
    assert_select "#user-menu a", count: 2
  end

  test "the account button shows the avatar and the username, and is named for screen readers" do
    get tables_path

    assert_select "button[aria-controls=user-menu]" do
      assert_select "span[aria-hidden=true]", text: "PL"
      assert_select "span.sr-only", text: "Menu du compte"
      assert_select "span.sr-only.sm\\:not-sr-only", text: "player"
    end
  end

  test "the account menu is hidden until the button opens it, and holds the links and log out" do
    get tables_path

    assert_select "#user-menu[hidden]" do
      assert_select "a[href=?]", tables_path, text: "Mes tables"
      assert_select "a[href=?]", settings_display_path, text: "Paramètres"
      assert_select "form[action=?] button", destroy_user_session_path, text: "Se déconnecter"
    end
  end

  test "on my tables page, my tables is the current link of the menu" do
    get tables_path

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Mes tables"
  end

  test "on the account settings, settings is the current link of the menu" do
    get settings_account_path

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "settings stays the current link when the account form comes back with an error" do
    patch settings_email_path, params: { user: { email: "player@example.com", current_password: "wrong" } }

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "on a phone, the logo keeps its name for screen readers" do
    get tables_path

    assert_select "nav a[href=?] span.sr-only.sm\\:not-sr-only", tables_path, text: "JDR en ligne"
  end

  test "a signed in user has no theme control in the navbar: the theme is set in the settings" do
    get tables_path

    assert_select "nav [data-controller=theme]", count: 0
    assert_select "nav [role=switch]", count: 0
  end

  test "a visitor gets the three theme choices as icons, their text kept for screen readers" do
    sign_out :user
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_select "nav [role=group][aria-label=?][data-controller=theme]", "Thème" do
      assert_select "button[aria-pressed=false][title=?] svg[aria-hidden=true] + span.sr-only", "Clair", text: "Clair"
      assert_select "button[title=?]", "Sombre"
      assert_select "button[title=?]", "Système"
    end
  end

  test "a visitor gets neither the account menu nor an avatar" do
    sign_out :user
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_select "#user-menu", count: 0
    assert_select "nav a", text: "Se connecter"
  end
end
