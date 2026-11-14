require "test_helper"

class NavbarTranslationTest < ActionDispatch::IntegrationTest
  test "a french visitor sees the navbar in french" do
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_select "nav a", text: "Se connecter"
    assert_select "nav a", text: "S'inscrire"
  end

  test "an english visitor sees the navbar in english" do
    get root_path, headers: { "Accept-Language" => "en" }

    assert_select "nav a", text: "Log in"
    assert_select "nav a", text: "Sign up"
  end

  test "a french user sees the log out button in french" do
    sign_in User.create!(email: "player@example.com", password: "password123", locale: "fr")

    get root_path

    assert_select "nav button", text: "Se déconnecter"
  end
end
