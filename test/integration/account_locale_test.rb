require "test_helper"

class AccountLocaleTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "player@example.com", password: TEST_PASSWORD, locale: "fr")
    sign_in @user
  end

  test "the account page offers the browser language and every available locale" do
    get edit_user_registration_path

    assert_select "select#user_locale option", count: 3
    assert_select "select#user_locale option[value='']", text: "Langue du navigateur"
    assert_select "select#user_locale option[selected][value='fr']", text: "Français"
    assert_select "select#user_locale option[value='en']", text: "English"
  end

  test "choosing english saves it and confirms in english" do
    update_locale_to "en"

    assert_equal "en", @user.reload.locale
    follow_redirect!
    assert_select "html[lang=?]", "en"
    assert_select "[role=status]", text: I18n.t("devise.registrations.updated", locale: :en)
  end

  test "choosing the browser language clears the saved locale" do
    update_locale_to ""

    assert_nil @user.reload.locale
  end

  test "an unavailable locale is refused" do
    update_locale_to "de"

    assert_response :unprocessable_content
    assert_equal "fr", @user.reload.locale
  end

  private

  def update_locale_to(locale)
    patch user_registration_path, params: { user: { locale: locale, current_password: TEST_PASSWORD } }
  end
end
