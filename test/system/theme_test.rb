require "application_system_test_case"

class ThemeTest < ApplicationSystemTestCase
  test "a visitor chooses the dark theme on the sign in page and keeps it after a reload" do
    visit new_user_session_path
    find("[data-theme-choice-param='dark']").click

    assert dark_theme_applied?
    assert_selector "[data-theme-choice-param='dark'][aria-pressed='true']"

    refresh

    assert dark_theme_applied?
  end

  test "a new visitor follows the system theme" do
    visit new_user_session_path

    assert_selector "[data-theme-choice-param='system'][aria-pressed='true']"
  end

  private

  def dark_theme_applied?
    page.evaluate_script("document.documentElement.classList.contains('dark')")
  end
end
