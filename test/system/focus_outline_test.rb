require "application_system_test_case"

class FocusOutlineTest < ApplicationSystemTestCase
  FOCUS_RING_LIGHT = "rgb(29, 87, 74)".freeze
  FOCUS_RING_DARK = "rgb(127, 209, 189)".freeze

  test "a link focused with the keyboard gets the theme green outline, not the browser blue" do
    visit new_user_session_path
    find("body").send_keys(:tab)

    assert_equal FOCUS_RING_LIGHT, focused_element_style("outlineColor")
    assert_equal "2px", focused_element_style("outlineWidth")
  end

  test "in the dark theme, the outline takes the lighter green" do
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
