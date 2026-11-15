require "test_helper"

class SignUpLocaleTest < ActionDispatch::IntegrationTest
  test "signing up with a french browser stores french" do
    sign_up_with_browser_language "fr-FR,fr;q=0.9"

    assert_equal "fr", User.last.locale
  end

  test "signing up with an unavailable browser language stores no locale" do
    sign_up_with_browser_language "de"

    assert_nil User.last.locale
  end

  test "signing up stores the first available browser preference" do
    sign_up_with_browser_language "de-DE,de;q=0.9,en;q=0.8"

    assert_equal "en", User.last.locale
  end

  test "the welcome message is shown in the detected language" do
    sign_up_with_browser_language "fr"
    follow_redirect!

    assert_select "[role=status]", text: I18n.t("devise.registrations.signed_up", locale: :fr)
  end

  private

  def sign_up_with_browser_language(accept_language)
    post user_registration_path,
         params: { user: { email: "new.player@example.com", password: TEST_PASSWORD,
                           password_confirmation: TEST_PASSWORD } },
         headers: { "Accept-Language" => accept_language }
  end
end
