require "test_helper"

class IconsTest < ActionView::TestCase
  ICON_NAMES = %w[sun moon plus link eye eye_off log_out check x chevron_down].freeze

  ICON_NAMES.each do |icon_name|
    test "the #{icon_name} icon is hidden from screen readers, 16 px and colored by its text" do
      render partial: "shared/icons/#{icon_name}"

      assert_select "svg[aria-hidden=true][stroke=currentColor][fill=none]", count: 1
      assert_select "svg.size-4"
      assert_select "svg[width], svg[height]", count: 0
    end
  end

  test "an icon accepts another size class" do
    render partial: "shared/icons/plus", locals: { css_class: "size-5" }

    assert_select "svg.size-5"
    assert_select "svg.size-4", count: 0
  end
end
