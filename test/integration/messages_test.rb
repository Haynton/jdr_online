require "test_helper"

class MessagesTest < ActionDispatch::IntegrationTest
  FRENCH_BROWSER = { "Accept-Language" => "fr" }.freeze

  test "a flash notice uses the success message" do
    user = User.create!(email: "player@example.com", password: "password123")
    sign_in user
    delete destroy_user_session_path
    follow_redirect!

    assert_select "div[role=status].bg-success-bg.border-success-ink\\/70 > svg[aria-hidden=true]"
  end

  test "an invalid sign up announces its errors to screen readers only, in french" do
    post user_registration_path,
         params: { user: { email: "", password: "", password_confirmation: "" } },
         headers: FRENCH_BROWSER.dup

    assert_response :unprocessable_content
    assert_select "form .sr-only div[role=alert]", text: "Merci de corriger les erreurs ci-dessous."
    assert_select ".error_notification", count: 0
  end

  test "on screen, the forgot password page shows its error on the field itself, in french" do
    post user_password_path, params: { user: { email: "nobody@example.com" } }, headers: FRENCH_BROWSER.dup

    assert_response :unprocessable_content
    assert_select "form .sr-only div[role=alert]", text: "Merci de corriger les erreurs ci-dessous."
    assert_select "input#user_email[aria-invalid=true] + p.text-error-ink"
  end
end
