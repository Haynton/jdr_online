require "application_system_test_case"

# The account entries of the side navigation (shared/_account_nav), from 768 px: the window is 1400 px wide
class AccountNavTest < ApplicationSystemTestCase
  setup do
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    sign_in_with_form
  end

  test "settings opens the settings window over the page, on the display section" do
    settings_link.click

    assert_selector "dialog#settings-dialog[open] #settings-section-title", text: /./
    assert_current_path game_tables_path
    assert page.evaluate_script("document.activeElement.id === 'settings-dialog'")
  end

  test "Escape closes the settings window" do
    settings_link.click
    assert_selector "dialog#settings-dialog[open]"

    find("dialog#settings-dialog").send_keys(:escape)

    assert_no_selector "dialog#settings-dialog[open]"
  end

  test "log out asks first in our own window, then leads back to the home page" do
    find("#side-nav form[action='#{destroy_user_session_path}'] button").click
    assert_selector "dialog#confirm-dialog[open] #confirm-dialog-question", text: /./

    find("dialog#confirm-dialog button[value=confirm]").click

    assert_current_path root_path
    assert_no_selector "#side-nav"
  end

  test "log out cancelled keeps the user signed in" do
    find("#side-nav form[action='#{destroy_user_session_path}'] button").click
    find("dialog#confirm-dialog button[value=cancel]").click

    assert_no_selector "dialog#confirm-dialog[open]"
    assert_current_path game_tables_path
    assert_selector "#side-nav"
  end

  private

  def sign_in_with_form
    visit new_user_session_path
    fill_in "user_email", with: "player@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
  end

  def settings_link
    find("#side-nav a[href='#{settings_display_path}'][data-turbo-frame=settings_dialog]")
  end
end
