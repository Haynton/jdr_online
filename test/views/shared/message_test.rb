require "test_helper"

class MessageTest < ActionView::TestCase
  test "an error message is announced at once, with the cross icon and a thin red border" do
    render layout: "shared/message", locals: { variant: :error } do
      "Invalid email or password."
    end

    assert_select "div[role=alert].bg-error-bg.text-error-ink.border.border-error-ink\\/70", text: /Invalid email/
    assert_select "div[role=alert] > svg[aria-hidden=true]", count: 1
  end

  test "a success message is announced politely, with the check icon and a thin green border" do
    render layout: "shared/message", locals: { variant: :success } do
      "Signed in successfully."
    end

    assert_select "div[role=status].bg-success-bg.text-success-ink.border.border-success-ink\\/70", text: /Signed in/
    assert_select "div[role=status] > svg[aria-hidden=true]", count: 1
  end

  test "no thick accent bar on any message" do
    %i[error success].each do |variant|
      assert_not_includes view.message_classes(variant), "border-l-4"
    end
  end

  test "an unknown variant fails loudly" do
    assert_raises(KeyError) { view.message_classes(:warning) }
  end
end
