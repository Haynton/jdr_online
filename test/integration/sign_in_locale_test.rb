require "test_helper"

class SignInLocaleTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "player@example.com", password: "password123", locale: "fr")
  end

  test "the sign in message uses the user's language, not the browser's" do
    post user_session_path,
         params: { user: { email: @user.email, password: "password123" } },
         headers: english_browser
    follow_redirect!(headers: english_browser)

    assert_select "[role=status]", text: I18n.t("devise.sessions.signed_in", locale: :fr)
  end

  test "the sign out message follows the browser, like the page that shows it" do
    sign_in @user

    delete destroy_user_session_path, headers: english_browser
    follow_redirect!(headers: english_browser)

    assert_select "html[lang=?]", "en"
    assert_select "[role=status]", text: I18n.t("devise.sessions.signed_out", locale: :en)
  end

  private

  # A new hash each time: follow_redirect! adds its own headers to the hash it receives
  def english_browser
    { "Accept-Language" => "en" }
  end
end
