require "application_system_test_case"

class SelectPickerTest < ApplicationSystemTestCase
  # Light theme value of primary-soft (#e4efe9), as the browser reports it
  PRIMARY_SOFT_LIGHT = "rgb(228, 239, 233)".freeze

  test "in a browser that supports it, the open list of a select uses our colors" do
    visit dev_components_path
    assert page.evaluate_script("CSS.supports('appearance', 'base-select')"),
           "the Chrome used by the tests should support appearance: base-select"

    assert_equal "base-select", computed_style("#user_locale", "appearance")

    find("#user_locale").click

    assert page.evaluate_script("document.querySelector('#user_locale').matches(':open')")
    assert_equal PRIMARY_SOFT_LIGHT, computed_style("#user_locale option:checked", "background-color")
  end

  # With base-select, the first arrow opens the list and moves the focus to an option:
  # the next keys go to whatever has the focus, like a real keyboard, not to the select itself
  test "the select stays usable with the keyboard" do
    visit dev_components_path

    find("#user_locale").send_keys(:arrow_down)
    assert page.evaluate_script("document.querySelector('#user_locale').matches(':open')")

    page.driver.browser.action.send_keys(:arrow_down, :enter).perform

    assert_equal "fr", page.evaluate_script("document.querySelector('#user_locale').value")
    assert_not page.evaluate_script("document.querySelector('#user_locale').matches(':open')")
  end

  private

  def computed_style(css_selector, property)
    page.evaluate_script("getComputedStyle(document.querySelector('#{css_selector}')).getPropertyValue('#{property}')")
  end
end
