require "test_helper"

class PasswordLengthHintTest < ActionDispatch::IntegrationTest
  test "the sign up page announces the minimum length, in french" do
    get new_user_registration_path, headers: { "Accept-Language" => "fr" }

    assert_select "div:has(> input#user_password) + p", text: "12 caractères minimum"
  end

  test "the sign up page announces the minimum length, in english" do
    get new_user_registration_path, headers: { "Accept-Language" => "en" }

    assert_select "div:has(> input#user_password) + p", text: "12 characters minimum"
  end

  test "the new password page announces the minimum length" do
    get edit_user_password_path(reset_password_token: "any-token"), headers: { "Accept-Language" => "fr" }

    assert_select "div:has(> input#user_password) + p", text: "12 caractères minimum"
  end
end
