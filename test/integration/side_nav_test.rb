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

  test "the navigation holds the logo, my tables, settings and log out" do
    get game_tables_path

    assert_select "#side-nav" do
      assert_select "a[href=?] span#{fading_text_selector}", game_tables_path, text: "JDR en ligne"
      assert_select "a[href=?][title=?]", game_tables_path, "Mes tables" do
        assert_select "svg[aria-hidden=true] + span#{fading_text_selector}", text: "Mes tables"
      end
      assert_select "#{account_entries_selector} a[href=?][title=?]", settings_display_path, "Paramètres"
      assert_select "#{account_entries_selector} form[action=?][data-turbo-confirm=?] button[title=?]",
                    destroy_user_session_path, "Se déconnecter ?", "Se déconnecter"
    end
  end

  test "only the logo and the unfolding button at the top; my tables opens the group at the foot" do
    get game_tables_path

    assert_select "#side-nav > a[href=?] + div > button[data-action='side-nav#toggle']", game_tables_path
    assert_select "#side-nav > div:has(> button[data-action='side-nav#toggle']) + div.md\\:mt-auto > a[href=?]",
                  game_tables_path, text: "Mes tables"
    assert_select "#side-nav > div.md\\:mt-auto + div.md\\:hidden + div.hidden.md\\:flex"
  end

  test "on my tables page, my tables is the current link of the navigation" do
    get game_tables_path

    assert_select "#side-nav > div > a[aria-current=page][href=?]", game_tables_path, count: 1, text: "Mes tables"
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

  test "from 768 px, the avatar and the username only show who is signed in" do
    get game_tables_path

    assert_select "#{account_entries_selector} > div[title=?]", "player" do
      assert_select "span[aria-hidden=true]", text: "PL"
      assert_select "span#{fading_text_selector}", text: "player"
    end
    assert_select "#{account_entries_selector} > div a, #{account_entries_selector} > div button", count: 0
  end

  test "the bar slides open, and the page beside it, unless the device asks for less motion" do
    get game_tables_path

    assert_select "nav#side-nav.motion-safe\\:md\\:transition-\\[width\\]"
    assert_select "body > div.motion-safe\\:md\\:transition-\\[padding\\]"
  end

  test "on a phone, the gear leads to the settings page, without the avatar" do
    get game_tables_path

    assert_select "#side-nav > div.md\\:hidden a[href=?][title=?]", settings_path, "Paramètres" do
      assert_select "svg[aria-hidden=true] + span#{fading_text_selector}", text: "Paramètres"
    end
    assert_select "#side-nav > div.md\\:hidden span[aria-hidden=true]", text: "PL", count: 0
    assert_select account_entries_selector
  end

  test "on a phone, the gear is the current link on the settings" do
    get settings_account_path

    assert_select "#side-nav > div.md\\:hidden a[aria-current=page][href=?]", settings_path
  end

  test "on the account settings, settings is the current link of the navigation" do
    get settings_account_path

    assert_select "#{account_entries_selector} a[aria-current=page]", count: 1, text: "Paramètres"
  end

  test "settings stays the current link when the account form comes back with an error" do
    patch settings_email_path, params: { user: { email: "player@example.com", current_password: "wrong" } }

    assert_select "#{account_entries_selector} a[aria-current=page]", count: 1, text: "Paramètres"
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

  # Settings, log out and who is signed in, from 768 px (shared/_account_nav)
  def account_entries_selector
    "#side-nav div.hidden.md\\:flex"
  end
end
