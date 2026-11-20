require "test_helper"

class PasswordInputTest < ActionView::TestCase
  test "a password field keeps the field style and leaves room for the button on its right" do
    render_password_field

    assert_select "div.relative[data-controller=password-visibility] > input#user_password[type=password]"
    assert_select "input#user_password.border-transparent.bg-field.pr-12[data-password-visibility-target=field]"
  end

  test "the button is hidden until JavaScript runs, and does not send the form" do
    render_password_field

    assert_select "input#user_password + button[type=button][hidden][aria-pressed=false]"
  end

  test "the button has a translated label, its icons are hidden from screen readers" do
    I18n.with_locale(:fr) { render_password_field }

    assert_select "button[aria-label=?]", "Afficher le mot de passe"
    assert_select "button svg[aria-hidden=true]", count: 2
  end

  test "the password is hidden again when a form is sent" do
    render_password_field

    assert_select "div[data-action=?]", "submit@document->password-visibility#hide"
  end

  private

  def render_password_field
    rendered.concat(view.simple_form_for(User.new, url: "/") { |form| form.input(:password) })
  end
end
