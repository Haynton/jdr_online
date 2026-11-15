require "test_helper"

class SwitchTest < ActionView::TestCase
  test "a switch is a button with the switch role, named by its visible text, off by default" do
    render partial: "shared/switch", locals: { labelled_by: "noise-label" }

    assert_select "button[type=button][role=switch][aria-checked=false][aria-labelledby=noise-label]"
    assert_select "button[data-controller=switch][data-action='switch#toggle']"
  end

  test "a switch can start on, and its knob is hidden from screen readers" do
    render partial: "shared/switch", locals: { labelled_by: "push-label", checked: true }

    assert_select "button[role=switch][aria-checked=true] > span[aria-hidden=true]"
  end

  test "the off track is visible enough and the motion stops when the user asks for less" do
    render partial: "shared/switch", locals: { labelled_by: "noise-label" }

    assert_select "button.bg-field-line.aria-checked\\:bg-primary.motion-reduce\\:transition-none"
  end

  test "a switch can be disabled" do
    render partial: "shared/switch", locals: { labelled_by: "disabled-label", disabled: true }

    assert_select "button[role=switch][disabled]"
  end
end
