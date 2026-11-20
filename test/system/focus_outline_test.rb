require "application_system_test_case"

class FocusOutlineTest < ApplicationSystemTestCase
  # focus-ring of application.css: brass, #6b4d10 in the light theme and #e2c07c in the dark one
  FOCUS_RING_LIGHT = "rgb(107, 77, 16)".freeze
  FOCUS_RING_DARK = "rgb(226, 192, 124)".freeze

  test "a link focused with the keyboard gets the theme gold outline, not the browser blue" do
    visit new_user_session_path
    find("body").send_keys(:tab)

    assert_equal FOCUS_RING_LIGHT, focused_element_style("outlineColor")
    assert_equal "2px", focused_element_style("outlineWidth")
  end

  test "in the dark theme, the outline takes the lighter gold" do
    visit new_user_session_path
    page.execute_script("localStorage.setItem('theme', 'dark')")
    refresh
    find("body").send_keys(:tab)

    assert_equal FOCUS_RING_DARK, focused_element_style("outlineColor")
  end

  private

  def focused_element_style(property)
    page.evaluate_script("getComputedStyle(document.activeElement).#{property}")
  end
end
