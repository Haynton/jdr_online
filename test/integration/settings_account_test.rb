require "test_helper"

class SettingsAccountTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "player@example.com", password: TEST_PASSWORD, locale: "fr")
    sign_in @user
  end

  test "the account section shows the email form, log out and the danger zone" do
    get settings_account_path

    assert_response :success
    assert_select "h2", text: "Compte"
    assert_select "form[action=?] input#user_email[value=?]", settings_email_path, "player@example.com"
    assert_select "form[action=?] input#user_current_password[type=password]", settings_email_path
    assert_select "form[action=?] button.border-line", destroy_user_session_path, text: "Se déconnecter"
    assert_select "h3", text: "Zone sensible"
  end

  test "deleting the account is a danger button that asks for a confirmation first" do
    get settings_account_path

    assert_select "form[action=?] button.bg-danger[data-turbo-confirm]", user_registration_path, text: "Supprimer"
  end

  test "account is the current section of the menu" do
    get settings_account_path

    assert_select "nav a[href=?][aria-current=page]", settings_account_path, text: "Compte"
  end

  test "the email changes with the current password" do
    patch settings_email_path, params: { user: { email: "new.player@example.com", current_password: TEST_PASSWORD } }

    assert_equal "new.player@example.com", @user.reload.email
    assert_redirected_to settings_account_path
    follow_redirect!
    assert_select "[role=status]", text: "Adresse e-mail modifiée."
  end

  test "a wrong current password keeps the email and shows the section again with the error" do
    patch settings_email_path, params: { user: { email: "new.player@example.com", current_password: "wrong" } }

    assert_response :unprocessable_content
    assert_equal "player@example.com", @user.reload.email
    assert_select "input#user_current_password[aria-invalid=true]"
    assert_select "nav a[href=?][aria-current=page]", settings_account_path
  end

  test "the navbar keeps the saved email when the change is refused" do
    patch settings_email_path, params: { user: { email: "new.player@example.com", current_password: "wrong" } }

    assert_select "button[aria-controls=user-menu]", text: /player@example\.com/
    assert_select "button[aria-controls=user-menu]", text: /new\.player/, count: 0
  end

  test "only the email can be changed this way" do
    patch settings_email_path, params: { user: { email: "player@example.com", current_password: TEST_PASSWORD,
                                                 locale: "en", password: "another-long-password" } }

    @user.reload
    assert_equal "fr", @user.locale
    assert @user.valid_password?(TEST_PASSWORD)
  end

  test "deleting the account removes it and goes back to the home page" do
    delete user_registration_path

    assert_nil User.find_by(id: @user.id)
    assert_redirected_to root_path
  end

  test "a visitor is sent to the sign in page" do
    sign_out :user
    get settings_account_path

    assert_redirected_to new_user_session_path
  end
end
