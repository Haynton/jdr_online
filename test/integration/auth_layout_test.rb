require "test_helper"

class AuthLayoutTest < ActionDispatch::IntegrationTest
  test "the visitor pages use the auth layout: no navbar, the logo links home, the theme control is there" do
    [new_user_session_path, new_user_registration_path, new_user_password_path].each do |visitor_page_path|
      get visitor_page_path

      assert_auth_layout
    end
  end

  test "a sign up page shown again after an error keeps the auth layout" do
    post user_registration_path, params: { user: { email: "", password: "", password_confirmation: "" } }

    assert_response :unprocessable_content
    assert_auth_layout
  end

  test "the old account page leads to the account settings, and its old form changes nothing" do
    user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    sign_in user

    get edit_user_registration_path
    assert_redirected_to settings_account_path

    patch user_registration_path, params: { user: { email: "new.player@example.com", current_password: TEST_PASSWORD } }
    assert_redirected_to settings_account_path
    assert_equal "player@example.com", user.reload.email
  end

  private

  def assert_auth_layout
    assert_select "nav", count: 0
    assert_select "header a[href=?] svg[aria-hidden=true]", root_path
    assert_select "header [role=group][data-controller=theme]"
    assert_select "main.max-w-\\[400px\\].justify-center"
  end
end
