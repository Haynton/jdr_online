require "test_helper"

class AuthPagesTest < ActionDispatch::IntegrationTest
  test "each visitor page shows its title in a card, as the page heading" do
    visitor_page_titles.each do |visitor_page_path, title|
      get visitor_page_path, headers: { "Accept-Language" => "fr" }

      assert_select "section.bg-surface[aria-labelledby=auth-card-title] h1#auth-card-title", text: title
    end
  end

  test "the sign in page title and subtitle are translated" do
    get new_user_session_path, headers: { "Accept-Language" => "en" }

    assert_select "h1", text: "Sign in"
    assert_select "h1 + p", text: "Find your game tables."
  end

  test "the new password page has no subtitle" do
    get edit_user_password_path(reset_password_token: "any-token")

    assert_select "h1 + p", count: 0
  end

  test "the sign in page separates the form from the sign up offer" do
    get new_user_session_path, headers: { "Accept-Language" => "fr" }

    assert_select "span.h-px.bg-line[aria-hidden=true]", count: 2
    assert_select "span", text: "Nouveau ici ?"
  end

  test "an expired reset link is reported with a way to get a new one" do
    put user_password_path, params: { user: reset_password_params("expired-token") },
                            headers: { "Accept-Language" => "fr" }

    assert_select "[role=alert] a[href=?]", new_user_password_path, text: "Recevoir un nouveau lien"
  end

  private

  def visitor_page_titles
    {
      new_user_session_path => "Connexion",
      new_user_registration_path => "Créer un compte",
      new_user_password_path => "Recevoir un lien",
      edit_user_password_path(reset_password_token: "any-token") => "Nouveau mot de passe"
    }
  end

  def reset_password_params(token)
    { reset_password_token: token, password: "new-password-123", password_confirmation: "new-password-123" }
  end
end
