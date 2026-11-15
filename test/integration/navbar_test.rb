require "test_helper"

class NavbarTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.create!(email: "player@example.com", password: TEST_PASSWORD, locale: "fr")
  end

  test "a signed in user sees the logo, the theme switch and the account button, no other link" do
    get root_path

    assert_select "nav[aria-label=?]", "Navigation principale" do
      assert_select "nav > a[href=?]", root_path
      assert_select "button[role=switch]"
      assert_select "button[aria-expanded=false][aria-controls=user-menu]"
    end
    assert_select "nav a", count: 3, message: "only the logo and the two links of the menu"
    assert_select "#user-menu a", count: 2
  end

  test "the account button shows the avatar and the email, and is named for screen readers" do
    get root_path

    assert_select "button[aria-controls=user-menu]" do
      assert_select "span[aria-hidden=true]", text: "PL"
      assert_select "span.sr-only", text: "Menu du compte"
      assert_select "span.sr-only.sm\\:not-sr-only", text: "player@example.com"
    end
  end

  test "the account menu is hidden until the button opens it, and holds the links and log out" do
    get root_path

    assert_select "#user-menu[hidden]" do
      assert_select "a[href=?]", root_path, text: "Mes tables"
      assert_select "a[href=?]", edit_user_registration_path, text: "Paramètres"
      assert_select "form[action=?] button", destroy_user_session_path, text: "Se déconnecter"
    end
  end

  test "on the home page, my tables is the current link of the menu" do
    get root_path

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Mes tables"
  end

  test "on the account page, settings is the current link of the menu" do
    get edit_user_registration_path

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "settings stays the current link when the account form comes back with an error" do
    patch user_registration_path, params: { user: { email: "player@example.com", current_password: "wrong" } }

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "on a phone, the logo keeps its name for screen readers" do
    get root_path

    assert_select "nav a[href=?] span.sr-only.sm\\:not-sr-only", root_path, text: "JDR en ligne"
  end

  test "a signed in user gets the light or dark switch, not the three theme choices" do
    get root_path

    assert_select "nav button[role=switch][aria-label=?][data-action='theme#toggle']", "Thème sombre"
    assert_select "nav [role=group]", count: 0
  end

  test "a visitor keeps the three theme choices, without the switch" do
    sign_out :user
    get root_path

    assert_select "nav [role=group] button", count: 3
    assert_select "nav [role=switch]", count: 0
  end

  test "a visitor gets neither the account menu nor an avatar" do
    sign_out :user
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_select "#user-menu", count: 0
    assert_select "nav a", text: "Se connecter"
  end
end
