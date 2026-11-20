require "test_helper"

class SideNavTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
  end

  test "a signed in user gets the side navigation instead of the top bar" do
    get game_tables_path

    assert_select "nav#side-nav[aria-label=?][data-controller=side-nav]", "Navigation principale"
    assert_select "nav", text: /Se connecter/, count: 0
    assert_select "nav[aria-label=?]", "Navigation principale", count: 1
  end

  test "the page leaves room for the navigation: under the floating bar of a phone, on the left from 768 px" do
    get game_tables_path

    assert_select "body > div.pb-20.md\\:pl-16.md\\:nav-expanded\\:pl-60"
  end

  test "the navigation holds the logo, my tables and the account button" do
    get game_tables_path

    assert_select "#side-nav" do
      assert_select "a[href=?] span#{fading_text_selector}", game_tables_path, text: "JDR en ligne"
      assert_select "a[href=?][title=?]", game_tables_path, "Mes tables" do
        assert_select "svg[aria-hidden=true] + span#{fading_text_selector}", text: "Mes tables"
      end
      assert_select "button[aria-expanded=false][aria-controls=user-menu]"
    end
  end

  test "on my tables page, my tables is the current link of the navigation" do
    get game_tables_path

    assert_select "#side-nav > a[aria-current=page]", count: 1, text: "Mes tables"
  end

  test "the button that unfolds the navigation is hidden until its controller shows it, and says what it does" do
    get game_tables_path

    assert_select "#side-nav[data-side-nav-expand-label-value=?][data-side-nav-collapse-label-value=?]",
                  "Déplier le menu", "Replier le menu"
    assert_select "#side-nav button[hidden][title=?][aria-controls=side-nav][data-action='side-nav#toggle']",
                  "Déplier le menu" do
      assert_select "span.sr-only.nav-expanded\\:hidden", text: "Déplier le menu"
      assert_select "span.invisible.nav-expanded\\:visible#{fading_text_selector}", text: "Replier le menu"
    end
  end

  test "the account button shows the avatar, and keeps the username for screen readers" do
    get game_tables_path

    assert_select "button[aria-controls=user-menu]" do
      assert_select "span[aria-hidden=true]", text: "PL"
      assert_select "span.sr-only", text: "Menu du compte"
      assert_select "span#{fading_text_selector}", text: "player"
    end
  end

  test "the bar slides open, and the page beside it, unless the device asks for less motion" do
    get game_tables_path

    assert_select "nav#side-nav.motion-safe\\:md\\:transition-\\[width\\]"
    assert_select "body > div.motion-safe\\:md\\:transition-\\[padding\\]"
  end

  test "the account menu is hidden until the button opens it, and holds the settings and log out" do
    get game_tables_path

    assert_select "#user-menu[hidden]" do
      assert_select "a", count: 1
      assert_select "a[href=?]", settings_display_path, text: "Paramètres"
      assert_select "form[action=?] button", destroy_user_session_path, text: "Se déconnecter"
    end
  end

  test "on a phone, the avatar leads straight to the settings; the menu is for wider screens" do
    get game_tables_path

    assert_select "#side-nav a.md\\:hidden[href=?][title=?]", settings_path, "Paramètres" do
      assert_select "span[aria-hidden=true]", text: "PL"
      assert_select "span.sr-only", text: "Paramètres"
    end
    assert_select "#side-nav div.hidden.md\\:block[data-controller=dropdown] button[aria-controls=user-menu]"
  end

  test "on a phone, the avatar link is the current one on the settings" do
    get settings_account_path

    assert_select "#side-nav a.md\\:hidden[aria-current=page][href=?]", settings_path
  end

  test "on the account settings, settings is the current link of the menu" do
    get settings_account_path

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "settings stays the current link when the account form comes back with an error" do
    patch settings_email_path, params: { user: { email: "player@example.com", current_password: "wrong" } }

    assert_select "#user-menu a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "a signed in user has no theme control in the navigation: the theme is set in the settings" do
    get game_tables_path

    assert_select "nav [data-controller=theme]", count: 0
  end

  test "the folded state is read before the page is painted, like the theme" do
    get game_tables_path

    assert_select "head script[src*='side_nav_preload']"
  end

  private

  # A text of the navigation: for screen readers only on a phone, transparent until the bar is unfolded from 768 px
  def fading_text_selector
    ".max-md\\:sr-only.md\\:opacity-0.md\\:nav-expanded\\:opacity-100"
  end
end
