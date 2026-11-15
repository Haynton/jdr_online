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

  test "an invalid sign up shows the error message at the top of the form, in french" do
    post user_registration_path,
         params: { user: { email: "", password: "", password_confirmation: "" } },
         headers: FRENCH_BROWSER.dup

    assert_response :unprocessable_content
    assert_select "form div[role=alert].bg-error-bg", text: "Merci de corriger les erreurs ci-dessous."
    assert_select ".error_notification", count: 0
  end

  test "the devise error list uses the error message" do
    post user_password_path, params: { user: { email: "nobody@example.com" } }, headers: FRENCH_BROWSER.dup

    assert_select "#error_explanation div[role=alert].bg-error-bg li", minimum: 1
  end
end
