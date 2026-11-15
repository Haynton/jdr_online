require "application_system_test_case"

class FieldHintTest < ApplicationSystemTestCase
  test "the password hint is shown, then replaced by the error message once the password is refused" do
    visit new_user_registration_path
    assert_selector password_hint_selector

    fill_in "user_email", with: "new.player@example.com"
    fill_in "user_password", with: "too-short"
    fill_in "user_password_confirmation", with: "too-short"
    find("input[type=submit]").click

    assert_selector "input#user_password[aria-invalid=true]"
    assert_no_selector password_hint_selector
  end

  private

  def password_hint_selector
    "div:has(> input#user_password) + p.text-muted"
  end
end
