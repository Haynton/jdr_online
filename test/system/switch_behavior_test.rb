require "application_system_test_case"

class SwitchBehaviorTest < ApplicationSystemTestCase
  setup do
    visit dev_components_path
    # Records every switch:change event so the test can read what the page was told
    page.execute_script(<<~JS)
      window.switchChanges = [];
      document.addEventListener("switch:change", (event) => window.switchChanges.push(event.detail.checked));
    JS
  end

  test "a click turns the switch on, then off, and tells the page each time" do
    find("#switch-noise").click
    assert_selector "#switch-noise[aria-checked=true]"

    find("#switch-noise").click
    assert_selector "#switch-noise[aria-checked=false]"

    assert_equal [true, false], page.evaluate_script("window.switchChanges")
  end

  test "the keyboard works like the mouse" do
    find("#switch-push").send_keys(:space)
    assert_selector "#switch-push[aria-checked=false]"

    find("#switch-push").send_keys(:enter)
    assert_selector "#switch-push[aria-checked=true]"
  end

  test "a disabled switch does not change" do
    page.execute_script("document.getElementById('switch-disabled').click()")

    assert_selector "#switch-disabled[aria-checked=false]"
    assert_equal [], page.evaluate_script("window.switchChanges")
  end
end
