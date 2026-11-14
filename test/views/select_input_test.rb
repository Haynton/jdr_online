require "test_helper"

class SelectInputTest < ActionView::TestCase
  test "a select keeps the field style, hides the browser arrow and shows the chevron icon" do
    render_locale_select

    assert_select "div.relative > select#user_locale.select-picker.appearance-none.border-field-line.bg-field"
    assert_select "div.relative > select#user_locale + svg[aria-hidden=true].pointer-events-none.text-muted"
  end

  test "a select stays a native select linked to its label" do
    render_locale_select

    assert_select "label[for=user_locale]"
    assert_select "select#user_locale option", count: 3
  end

  private

  # simple_form_for is a view helper: it is called on the test view, and assert_select reads rendered
  def render_locale_select
    form = view.simple_form_for(User.new, url: "/") do |form_builder|
      form_builder.input(:locale, collection: [%w[Français fr], %w[English en]], include_blank: "Browser language")
    end
    rendered.concat(form)
  end
end
