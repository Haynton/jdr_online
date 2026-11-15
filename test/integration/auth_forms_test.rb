require "test_helper"

class AuthFormsTest < ActionDispatch::IntegrationTest
  test "the sign in page uses the styled fields and a primary button" do
    get new_user_session_path

    assert_select "input#user_email.border-field-line"
    assert_select "input#user_password.border-field-line"
    assert_select "input[type=checkbox]#user_remember_me.appearance-none"
    assert_select "form input[type=submit].bg-primary", count: 1
  end

  test "the forgot password page uses the styled field and a primary button" do
    get new_user_password_path

    assert_select "input#user_email.border-field-line"
    assert_select "form input[type=submit].bg-primary", count: 1
  end

  test "the forgot password button has a short text, in both languages" do
    get new_user_password_path, headers: { "Accept-Language" => "fr" }
    assert_select "input[type=submit][value=?]", "Envoyer le lien"

    get new_user_password_path, headers: { "Accept-Language" => "en" }
    assert_select "input[type=submit][value=?]", "Send the link"
  end

  test "the new password page uses the styled fields and a primary button" do
    get edit_user_password_path(reset_password_token: "any-token")

    assert_select "input#user_password.border-field-line"
    assert_select "input#user_password_confirmation.border-field-line"
    assert_select "form input[type=submit].bg-primary", count: 1
  end

  test "the links under the forms use the link style" do
    get new_user_session_path

    assert_select "a.text-link[href=?]", new_user_registration_path
    assert_select "a.text-link[href=?]", new_user_password_path
  end

  test "a field error starts with a capital letter" do
    post user_password_path, params: { user: { email: "nobody@example.com" } }

    assert_select "input#user_email + p.first-letter\\:uppercase"
  end

  test "a required field shows a discreet mark after its label, hidden from screen readers" do
    get new_user_registration_path

    assert_select "label[for=user_email]", text: /\AEmail \*\z/
    assert_select "label[for=user_email] > span.text-muted[aria-hidden=true]", text: "*"
    assert_select "label abbr", count: 0
  end

  test "no Bootstrap class is left on any visitor page" do
    visitor_form_paths.each do |visitor_page_path|
      get visitor_page_path

      assert_select ".btn, .error_notification, .form-control", count: 0
    end
  end

  private

  def visitor_form_paths
    [new_user_session_path, new_user_password_path, edit_user_password_path(reset_password_token: "any-token")]
  end
end
