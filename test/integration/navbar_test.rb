require "test_helper"

# The top bar of the visitor pages. A signed in user gets the side navigation (side_nav_test.rb)
class NavbarTest < ActionDispatch::IntegrationTest
  test "a visitor gets the three theme choices as icons, their text kept for screen readers" do
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_select "nav [role=group][aria-label=?][data-controller=theme]", "Thème" do
      assert_select "button[aria-pressed=false][title=?] svg[aria-hidden=true] + span.sr-only", "Clair", text: "Clair"
      assert_select "button[title=?]", "Sombre"
      assert_select "button[title=?]", "Système"
    end
  end

  test "a visitor gets neither the side navigation nor its account entries" do
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_select "#side-nav", count: 0
    assert_select "form[action=?]", destroy_user_session_path, count: 0
    assert_select "nav a", text: "Se connecter"
  end

  test "on a phone, the logo of the top bar keeps its name for screen readers" do
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_select "nav a[href=?] span.sr-only.sm\\:not-sr-only", root_path, text: "JDR en ligne"
  end
end
