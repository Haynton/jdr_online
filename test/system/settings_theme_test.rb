require "application_system_test_case"

class SettingsThemeTest < ApplicationSystemTestCase
  setup do
    User.create!(email: "player@example.com", password: TEST_PASSWORD)
    visit new_user_session_path
    fill_in "user_email", with: "player@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "button[aria-controls=user-menu]"
    visit settings_display_path
  end

  test "choosing dark in the settings applies it and updates the navbar switch" do
    find("main [data-theme-choice-param=dark]").click

    assert_selector "main [data-theme-choice-param=dark][aria-pressed=true]"
    assert_selector "nav button[role=switch][aria-checked=true]"
    assert page.evaluate_script("document.documentElement.classList.contains('dark')")
  end

  test "changing the language list saves it at once" do
    find("select#user_locale").select("Français")

    assert_selector "[role=status]", text: "Langue enregistrée."
    assert_selector "html[lang=fr]"
  end

  test "the navbar switch updates the choices of the settings" do
    find("nav button[role=switch]").click

    assert_selector "main [data-theme-choice-param=dark][aria-pressed=true]"
    assert_selector "main [data-theme-choice-param=system][aria-pressed=false]"
  end
end
