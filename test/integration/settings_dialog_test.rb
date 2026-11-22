require "test_helper"

class SettingsDialogTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
  end

  test "a signed in page holds the settings window: a title bar with the close cross, and an empty frame" do
    get game_tables_path

    assert_select "dialog#settings-dialog[aria-labelledby=settings-dialog-title][tabindex='-1'][data-controller=settings-dialog]" do
      assert_select "header h2#settings-dialog-title", text: "Paramètres"
      assert_select "header button[aria-label=?][data-action='settings-dialog#close']", "Fermer les paramètres"
      assert_select "turbo-frame#settings_dialog:empty"
    end
  end

  test "settings in the navigation loads the display section into the window, without prefetch" do
    get game_tables_path

    assert_select "#side-nav a[href=?][data-turbo-frame=settings_dialog][data-turbo-prefetch=false]",
                  settings_display_path, text: "Paramètres"
    assert_select "dialog#settings-dialog[data-turbo-prefetch=false]"
  end

  test "a settings page tells caches that it depends on the frame asking for it" do
    get settings_display_path

    assert_includes response.headers["Vary"], "Turbo-Frame"
  end

  test "on a settings page there is no window: settings leads to the page itself" do
    get settings_account_path

    assert_select "dialog#settings-dialog", count: 0
    assert_select "#side-nav a[href=?]:not([data-turbo-frame])", settings_display_path
  end

  test "a settings page wraps its menu and section in the frame of the window" do
    get settings_display_path

    assert_select "turbo-frame#settings_dialog" do
      assert_select "nav[aria-labelledby=settings-title] h1#settings-title", text: "Paramètres"
      assert_select "main section[aria-labelledby=settings-section-title]"
    end
  end

  test "asked for the window, a section answers with its frame: two columns, no menu title, no card" do
    get settings_account_path, headers: { "Turbo-Frame" => "settings_dialog" }

    assert_response :success
    assert_select "turbo-frame#settings_dialog > div.grid.h-full" do
      assert_select "nav.border-r[aria-labelledby=settings-title] h1#settings-title.hidden"
      assert_select "main section.overflow-y-auto:not(.rounded-xl) #settings-section-title", text: "Compte"
    end
  end

  test "in the window, the menu stays beside the section at any width, with no way back to the phone list" do
    get settings_account_path, headers: { "Turbo-Frame" => "settings_dialog" }

    assert_select "nav[aria-labelledby=settings-title]:not(.hidden)"
    assert_select "nav[aria-labelledby=settings-title] ul.space-y-1 a[aria-current=page]", text: "Compte"
    assert_select "nav[aria-labelledby=settings-title] a svg", count: 0
    assert_select "main a[href=?]", settings_path, count: 0
  end

  test "the settings page keeps its centered layout and its section card" do
    get settings_account_path

    assert_select "turbo-frame#settings_dialog > div.max-w-\\[1120px\\]"
    assert_select "main section.rounded-xl.bg-surface #settings-section-title", text: "Compte"
  end

  test "logging out and deleting the account reload the whole page, even in the window" do
    get settings_account_path, headers: { "Turbo-Frame" => "settings_dialog" }

    assert_select "form[action=?][data-turbo-frame=_top]", destroy_user_session_path
    assert_select "form[action=?][data-turbo-frame=_top]", user_registration_path
  end

  test "on the page, the frame targets the whole page: links and forms change the address" do
    get settings_display_path

    assert_select "turbo-frame#settings_dialog[target=_top]"
  end

  test "in the window, the frame keeps its links and forms, the language one included, and gives its language" do
    get settings_display_path, headers: { "Turbo-Frame" => "settings_dialog" }

    assert_select "turbo-frame#settings_dialog:not([target])" do
      assert_select "div[data-settings-language][lang=fr]"
      assert_select "form[action=?]:not([data-turbo-frame])", settings_locale_path
    end
  end

  test "a username changed in the window shows at once in the navigation behind it" do
    patch settings_username_path, params: { user: { username: "Gandalf" } }, headers: { "Turbo-Frame" => "settings_dialog" }
    follow_redirect!(headers: { "Turbo-Frame" => "settings_dialog" })

    assert_select "turbo-frame#settings_dialog turbo-stream[action=replace][target=account-identity] template" do
      assert_select "#account-identity[title=Gandalf] span", text: "Gandalf"
    end
  end

  test "the settings page draws its own navigation: no stream to refresh it" do
    get settings_account_path

    assert_select "turbo-stream", count: 0
    assert_select "#side-nav #account-identity[title=player]"
  end

  test "a visitor gets no settings window" do
    sign_out :user
    get root_path

    assert_select "dialog#settings-dialog", count: 0
  end
end
