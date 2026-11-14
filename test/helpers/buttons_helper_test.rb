require "test_helper"

class ButtonsHelperTest < ActionView::TestCase
  test "each variant brings its own colors" do
    assert_includes button_classes(:primary), "bg-primary text-white hover:bg-primary-hover"
    assert_includes button_classes(:secondary), "border border-line bg-surface text-ink"
    assert_includes button_classes(:quiet), "bg-transparent text-ink"
    assert_includes button_classes(:danger), "bg-danger text-white hover:bg-danger-hover"
  end

  test "every button shares the same shape and a visible keyboard focus" do
    %i[primary secondary quiet danger].each do |variant|
      assert_includes button_classes(variant), "rounded-lg font-semibold"
      assert_includes button_classes(variant), "focus-visible:outline-primary"
    end
  end

  test "the normal size is 44 px high and the default" do
    assert_includes button_classes(:primary), "h-11"
    assert_equal button_classes(:primary, size: :normal), button_classes(:primary)
  end

  test "the compact size is 36 px high" do
    assert_includes button_classes(:secondary, size: :compact), "h-9"
  end

  test "an unknown variant or size fails loudly instead of rendering an unstyled button" do
    assert_raises(KeyError) { button_classes(:primay) }
    assert_raises(KeyError) { button_classes(:primary, size: :huge) }
  end
end
