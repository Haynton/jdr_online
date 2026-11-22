require "test_helper"

class AlreadySignedInLocaleTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
  end

  test "opening the sign in page while signed in explains it in the user's language" do
    get new_user_session_path

    assert_already_signed_in_message_in :fr
  end

  test "opening the sign up page while signed in explains it in the user's language" do
    get new_user_registration_path

    assert_already_signed_in_message_in :fr
  end

  test "opening the forgotten password page while signed in explains it in the user's language" do
    get new_user_password_path

    assert_already_signed_in_message_in :fr
  end

  private

  # The user's tables show it already: for screen readers only, never a red message pushing the page down
  def assert_already_signed_in_message_in(locale)
    assert_redirected_to game_tables_path
    follow_redirect!
    assert_select ".sr-only [role=status]", text: I18n.t("devise.failure.already_authenticated", locale: locale)
    assert_select "[role=alert]", count: 0
  end
end
