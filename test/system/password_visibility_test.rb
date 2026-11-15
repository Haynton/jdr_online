require "application_system_test_case"

class PasswordVisibilityTest < ApplicationSystemTestCase
  setup do
    visit new_user_registration_path
    fill_in "user_password", with: TEST_PASSWORD
  end

  test "the button shows the password, then hides it again" do
    show_password_button.click
    assert_selector "input#user_password[type=text]"
    assert_selector "#{show_password_button_selector}[aria-pressed=true]"

    show_password_button.click
    assert_selector "input#user_password[type=password]"
    assert_selector "#{show_password_button_selector}[aria-pressed=false]"
  end

  test "each password field has its own button" do
    show_password_button.click

    assert_selector "input#user_password[type=text]"
    assert_selector "input#user_password_confirmation[type=password]"
  end

  test "the password is hidden again when the form is sent" do
    show_password_button.click
    keep_form_on_page_when_sent
    find("input[type=submit]").click

    assert_selector "input#user_password[type=password]"
  end

  private

  # Without it, the server answers with a new page and the test could not look at the field that was sent
  def keep_form_on_page_when_sent
    page.execute_script(<<~JS)
      document.getElementById("user_password").form.addEventListener("submit", (event) => event.preventDefault())
    JS
  end

  def show_password_button_selector
    "input#user_password + button"
  end

  def show_password_button
    find(show_password_button_selector)
  end
end
