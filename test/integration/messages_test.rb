require "test_helper"

class MessagesTest < ActionDispatch::IntegrationTest
  FRENCH_BROWSER = { "Accept-Language" => "fr" }.freeze

  test "a flash notice uses the success message" do
    user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    sign_in user
    delete destroy_user_session_path
    follow_redirect!

    assert_select "div[role=status].bg-success-bg.border-success-ink\\/70 > svg[aria-hidden=true]"
  end

  test "a wrong password shows a floating error, with a close button shown by its controller" do
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    post user_session_path, params: { user: { email: "player@example.com", password: "wrong password" } },
                            headers: FRENCH_BROWSER.dup

    assert_select "main > div.fixed [data-controller=toast][role=alert][data-toast-duration-value='10000']",
                  text: /Adresse e-mail ou mot de passe incorrect/i
    assert_select "[data-controller=toast] button[hidden][aria-label=?]", "Fermer le message"
  end

  test "after a password reset, the signed in message is for screen readers only" do
    user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    reset_token = user.send_reset_password_instructions
    put user_password_path, params: { user: { reset_password_token: reset_token, password: "#{TEST_PASSWORD}2",
                                              password_confirmation: "#{TEST_PASSWORD}2" } }
    follow_redirect!

    assert_select ".sr-only [role=status]", count: 1
    assert_select "[data-controller=toast]", count: 0
  end

  test "after the account is deleted, the goodbye message is for screen readers only" do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    delete user_registration_path
    follow_redirect!

    assert_select ".sr-only [role=status]", count: 1
    assert_select "[data-controller=toast]", count: 0
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
