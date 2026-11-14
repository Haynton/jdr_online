require "test_helper"

class SimpleFormFieldsTest < ActionView::TestCase
  setup do
    @invalid_user = User.new(email: "not-an-email").tap(&:validate)
  end

  test "a field has its label above it and the named field colors" do
    render_form { |form| form.input(:email) }

    assert_select "div.mb-4 > label.text-ink[for=user_email]"
    assert_select "input#user_email.border-field-line.bg-field.text-ink"
    assert_select "input#user_email.focus\\:outline-primary"
  end

  test "an invalid field is marked for screen readers and gets the error border and message" do
    render_form { |form| form.input(:email) }

    assert_select "input#user_email[aria-invalid=true].aria-invalid\\:border-error-ink"
    assert_select "input#user_email + p.text-error-ink"
  end

  test "a hint is shown under the field in the secondary color" do
    render_form { |form| form.input(:password, hint: "At least 6 characters") }

    assert_select "p.text-muted", text: "At least 6 characters"
  end

  test "a check box sits inside its label and uses the primary color" do
    render_form { |form| form.input(:remember_me, as: :boolean) }

    assert_select "label.inline-flex.text-ink > input[type=checkbox].accent-primary"
  end

  test "no class left over from Bootstrap" do
    render_form { |form| form.input(:email) + form.input(:remember_me, as: :boolean) }

    assert_select ".checkbox, .field_with_errors, .form-control", count: 0
  end

  private

  # simple_form_for is a view helper: it is called on the test view, and assert_select reads rendered
  def render_form(&)
    rendered.concat(view.simple_form_for(@invalid_user, url: "/", &))
  end
end
