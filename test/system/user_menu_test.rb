require "application_system_test_case"

class UserMenuTest < ApplicationSystemTestCase
  setup do
    User.create!(email: "player@example.com", password: TEST_PASSWORD)
    sign_in_with_form
  end

  test "the account button opens the menu, then closes it" do
    account_button.click
    assert_selector "#user-menu", visible: true
    assert_selector "#{account_button_selector}[aria-expanded=true]"

    account_button.click
    assert_selector "#user-menu", visible: :hidden
    assert_selector "#{account_button_selector}[aria-expanded=false]"
  end

  test "Escape closes the menu and gives the focus back to the button" do
    account_button.click
    find("#user-menu a", match: :first).send_keys(:escape)

    assert_selector "#user-menu", visible: :hidden
    assert page.evaluate_script("document.activeElement.getAttribute('aria-controls') === 'user-menu'")
  end

  test "a click elsewhere on the page closes the menu" do
    account_button.click
    find("main").click

    assert_selector "#user-menu", visible: :hidden
  end

  test "the keyboard focus leaving the menu closes it" do
    account_button.click
    page.execute_script("document.querySelector('nav a').focus()")

    assert_selector "#user-menu", visible: :hidden
  end

  test "the menu leads to the settings and logs out" do
    account_button.click
    find("#user-menu a[href='#{settings_display_path}']").click
    assert_current_path settings_display_path

    account_button.click
    find("#user-menu form button").click

    assert_current_path root_path
    assert_no_selector account_button_selector
  end

  private

  def sign_in_with_form
    visit new_user_session_path
    fill_in "user_email", with: "player@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector account_button_selector
  end

  def account_button_selector
    "button[aria-controls=user-menu]"
  end

  def account_button
    find(account_button_selector)
  end
end
