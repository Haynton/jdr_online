require "test_helper"

class LogoTest < ActionView::TestCase
  test "the d20 is decorative and uses the named logo color, never a raw color" do
    render partial: "shared/logo"

    assert_select "svg[aria-hidden=true].text-white"
    assert_select "svg rect.fill-logo-bg:not([fill])"
    assert_select "svg path[stroke=currentColor]", count: 2
    assert_no_match(/#[0-9a-fA-F]{3,6}\b/, rendered)
  end

  test "the name is the same in both languages" do
    french_logo = I18n.with_locale(:fr) { render partial: "shared/logo" }
    english_logo = I18n.with_locale(:en) { render partial: "shared/logo" }

    assert_includes french_logo, "Fumble Quest"
    assert_includes english_logo, "Fumble Quest"
  end
end
