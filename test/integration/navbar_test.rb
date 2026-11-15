require "test_helper"

class NavbarTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.create!(email: "player@example.com", password: TEST_PASSWORD, locale: "fr")
  end

  test "a signed in user sees the main links, the avatar and the email" do
    get root_path

    assert_select "nav[aria-label=?]", "Navigation principale" do
      assert_select "a[href=?]", root_path, text: "Mes tables"
      assert_select "a[href=?]", edit_user_registration_path, text: "Mon compte"
      assert_select "span[aria-hidden=true]", text: "PL"
      assert_select "span", text: "player@example.com"
    end
  end

  test "on the home page, my tables is the current link" do
    get root_path

    assert_select "nav a[aria-current=page]", count: 1, text: "Mes tables"
  end

  test "on the account page, my account is the current link" do
    get edit_user_registration_path

    assert_select "nav a[aria-current=page]", count: 1, text: "Mon compte"
  end

  test "my account stays the current link when the account form comes back with an error" do
    patch user_registration_path, params: { user: { email: "player@example.com", current_password: "wrong" } }

    assert_select "nav a[aria-current=page]", count: 1, text: "Mon compte"
  end

  test "a signed in user can still log out from the navbar, until the settings page exists" do
    get root_path

    assert_select "nav form[action=?] button", destroy_user_session_path, text: "Se déconnecter"
  end

  test "on a phone, the avatar alone links to the account, named for screen readers" do
    get edit_user_registration_path

    assert_select "nav a.sm\\:hidden[href=?][aria-label=?][aria-current=page]",
                  edit_user_registration_path, "Mon compte" do
      assert_select "span[aria-hidden=true]", text: "PL"
    end
  end

  test "on a phone, the logo and the log out button keep their names for screen readers" do
    get root_path

    assert_select "nav a[href=?] span.sr-only.sm\\:not-sr-only", root_path, text: "JDR en ligne"
    assert_select "nav form button span.sr-only.sm\\:not-sr-only", text: "Se déconnecter"
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

  test "a visitor sees neither the main links nor an avatar" do
    sign_out :user
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_select "nav a", text: "Mes tables", count: 0
    assert_select "nav a", text: "Mon compte", count: 0
    assert_select "nav a", text: "Se connecter"
  end
end
