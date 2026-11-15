require "test_helper"

class SettingsSecurityTest < ActionDispatch::IntegrationTest
  NEW_PASSWORD = "another-long-password".freeze

  setup do
    @user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sign_in @user
  end

  test "the security section shows the password form" do
    get settings_security_path

    assert_response :success
    assert_select "h2", text: "Sécurité"
    assert_select "form[action=?]", settings_password_path do
      assert_select "input#user_current_password[type=password]"
      assert_select "input#user_password[type=password][autocomplete=new-password]"
      assert_select "input#user_password_confirmation[type=password]"
      assert_select "p", text: "12 caractères minimum"
      assert_select "input[type=submit][value=?]", "Changer le mot de passe"
    end
  end

  test "security is the current section of the menu" do
    get settings_security_path

    assert_select "nav a[href=?][aria-current=page]", settings_security_path, text: "Sécurité"
  end

  test "the password changes with the current one, and the user stays signed in" do
    change_password(current: TEST_PASSWORD, new: NEW_PASSWORD, confirmation: NEW_PASSWORD)

    assert @user.reload.valid_password?(NEW_PASSWORD)
    assert_redirected_to settings_security_path
    follow_redirect!
    assert_response :success
    assert_select "[role=status]", text: "Mot de passe modifié."
  end

  test "a wrong current password keeps the password and shows the section again" do
    change_password(current: "wrong", new: NEW_PASSWORD, confirmation: NEW_PASSWORD)

    assert_response :unprocessable_content
    assert @user.reload.valid_password?(TEST_PASSWORD)
    assert_select "input#user_current_password[aria-invalid=true]"
    assert_select "nav a[href=?][aria-current=page]", settings_security_path
  end

  test "an empty new password is refused instead of reported as changed" do
    change_password(current: TEST_PASSWORD, new: "", confirmation: "")

    assert_response :unprocessable_content
    assert_select "input#user_password[aria-invalid=true]"
  end

  test "a new password too short is refused" do
    change_password(current: TEST_PASSWORD, new: "too-short", confirmation: "too-short")

    assert_response :unprocessable_content
    assert @user.reload.valid_password?(TEST_PASSWORD)
  end

  test "a confirmation that does not match is refused" do
    change_password(current: TEST_PASSWORD, new: NEW_PASSWORD, confirmation: "something-else-entirely")

    assert_response :unprocessable_content
    assert_select "input#user_password_confirmation[aria-invalid=true]"
  end

  test "a visitor is sent to the sign in page" do
    sign_out :user
    get settings_security_path

    assert_redirected_to new_user_session_path
  end

  private

  def change_password(current:, new:, confirmation:)
    patch settings_password_path, params: { user: { current_password: current, password: new,
                                                    password_confirmation: confirmation } }
  end
end
