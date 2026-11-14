require "test_helper"

class FailureAppLocaleTest < ActionDispatch::IntegrationTest
  test "a french visitor is asked to sign in in french" do
    visit_protected_page_with_browser_language "fr-FR,fr;q=0.9"

    assert_sign_in_request_in :fr
  end

  test "a visitor with an unavailable browser language is asked to sign in in english" do
    visit_protected_page_with_browser_language "de"

    assert_sign_in_request_in :en
  end

  private

  def visit_protected_page_with_browser_language(accept_language)
    headers = { "Accept-Language" => accept_language }
    get edit_user_registration_path, headers: headers
    assert_redirected_to new_user_session_path
    follow_redirect!(headers: headers)
  end

  def assert_sign_in_request_in(locale)
    assert_select "[role=alert]", text: I18n.t("devise.failure.unauthenticated", locale: locale)
  end
end
