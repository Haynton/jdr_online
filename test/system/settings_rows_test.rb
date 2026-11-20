require "application_system_test_case"

class SettingsRowsTest < ApplicationSystemTestCase
  setup do
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    visit new_user_session_path
    fill_in "user_email", with: "player@example.com"
    fill_in "user_password", with: TEST_PASSWORD
    find("input[type=submit]").click
    assert_selector "#side-nav"
  end

  test "every row has a line under it, except the last element of the section" do
    visit settings_display_path

    assert_equal [1, 0], bottom_line_widths
  end

  test "a form alone in its section has no line under it" do
    visit settings_security_path

    assert_equal [0], bottom_line_widths
  end

  private

  # The width of the line under each element of each group, as the browser draws it
  def bottom_line_widths
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("main section section > div > *"))
        .map((element) => parseFloat(getComputedStyle(element).borderBottomWidth))
    JS
  end
end
