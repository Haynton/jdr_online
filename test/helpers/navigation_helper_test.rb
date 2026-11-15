require "test_helper"

class NavigationHelperTest < ActionView::TestCase
  test "a link shows its icon before its label" do
    render_link(current: false)

    assert_select "a", text: "My tables" do
      assert_select "svg.size-5[aria-hidden=true]"
    end
  end

  test "the link of the current page is marked for screen readers, without a color of its own" do
    render_link(current: true)

    assert_select "a[aria-current=page].text-ink"
    assert_select "a.bg-primary-soft", count: 0
  end

  test "a link to another page is not marked" do
    render_link(current: false)

    assert_select "a[aria-current]", count: 0
  end

  test "a link takes the whole line of the menu and has a visible keyboard focus" do
    render_link(current: false)

    assert_select "a.w-full.hover\\:bg-surface-raised.focus-visible\\:outline-focus-ring"
  end

  test "a button of the menu looks like its links" do
    assert_equal NavigationHelper::NAV_ITEM_CLASSES, nav_item_classes
  end

  private

  # Through view, like a real page: called on the test itself, the icon's render would write into the test output
  def render_link(current:)
    rendered.concat(view.nav_link_to("My tables", "/tables", icon: "dices", current: current))
  end
end
