require "application_system_test_case"

class ThemeSwitchTest < ApplicationSystemTestCase
  setup do
    User.create!(email: "player@example.com", password: TEST_PASSWORD)
  end

  # Capybara keeps the same Chrome for every test and only clears cookies and storage:
  # an emulated dark device would leak into the next test
  teardown do
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  test "the switch turns the dark theme on, and the choice stays after a reload" do
    sign_in_with_form
    assert_selector "#{theme_switch_selector}[aria-checked=false]"

    find(theme_switch_selector).click

    assert dark_theme_applied?
    assert_selector "#{theme_switch_selector}[aria-checked=true]"

    refresh

    assert dark_theme_applied?
    assert_selector "#{theme_switch_selector}[aria-checked=true]"
  end

  test "in system mode, the switch shows the theme of the device, and a click leaves the system mode" do
    use_dark_device
    sign_in_with_form
    assert_selector "#{theme_switch_selector}[aria-checked=true]"

    find(theme_switch_selector).click

    assert_not dark_theme_applied?
    assert_equal "light", page.evaluate_script("localStorage.getItem('theme')")
  end

  private

  def sign_in_with_form
    visit new_user_session_path
    fill_in "user_email", with: "player@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "button[aria-controls=user-menu]"
  end

  def use_dark_device
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia", features: [{ name: "prefers-color-scheme", value: "dark" }]
    )
  end

  def theme_switch_selector
    "nav button[role=switch]"
  end

  def dark_theme_applied?
    page.evaluate_script("document.documentElement.classList.contains('dark')")
  end
end
