require "application_system_test_case"

class SettingsThemeTest < ApplicationSystemTestCase
  setup do
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    visit new_user_session_path
    fill_in "user_email", with: "player@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
    visit settings_display_path
  end

  test "choosing dark in the settings applies it and keeps it after a reload" do
    find("main [data-theme-choice-param=dark]").click

    assert_selector "main [data-theme-choice-param=dark][aria-pressed=true]"
    assert page.evaluate_script("document.documentElement.classList.contains('dark')")

    refresh

    assert_selector "main [data-theme-choice-param=dark][aria-pressed=true]"
  end

  test "changing the language list saves it at once" do
    find("select#user_locale").select("Français")

    assert_selector "[role=status]", text: "Langue enregistrée."
    assert_selector "html[lang=fr]"
  end
end
