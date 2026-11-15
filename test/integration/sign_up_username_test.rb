require "test_helper"

class SignUpUsernameTest < ActionDispatch::IntegrationTest
  test "the sign up form asks for the username first, with its rules under the field" do
    get new_user_registration_path, headers: { "Accept-Language" => "fr" }

    assert_select "form input:first-of-type#user_username[required][autofocus][autocomplete=nickname]"
    assert_select "label[for=user_username]", text: /Pseudo/
    assert_select "#user_username ~ *", text: /De 3 à 20 caractères/
  end

  test "signing up stores the username" do
    sign_up(username: "Gaël_le-Barde")

    assert_equal "Gaël_le-Barde", User.last.username
  end

  test "a username already taken is refused, with the field in red" do
    User.create!(email: "player@example.com", username: "barde", password: TEST_PASSWORD)

    assert_no_difference "User.count" do
      sign_up(username: "Barde")
    end
    assert_response :unprocessable_content
    assert_select "input#user_username[aria-invalid=true]"
    assert_select "#user_username ~ *", text: "est déjà pris par un autre joueur"
  end

  private

  def sign_up(username:)
    post user_registration_path,
         params: { user: { username: username, email: "new.player@example.com", password: TEST_PASSWORD,
                           password_confirmation: TEST_PASSWORD } },
         headers: { "Accept-Language" => "fr" }
  end
end
