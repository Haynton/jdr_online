require "test_helper"

class NavigationHelperTest < ActionView::TestCase
  test "the link of the current page is green and marked for screen readers" do
    render_link(current: true)

    assert_select "a.bg-primary-soft.text-primary-soft-ink.font-semibold[aria-current=page]"
  end

  test "a link to another page is discreet and not marked" do
    render_link(current: false)

    assert_select "a.text-muted"
    assert_select "a[aria-current]", count: 0
    assert_select "a.bg-primary-soft", count: 0
  end

  test "a link has a visible keyboard focus" do
    render_link(current: false)

    assert_select "a.focus-visible\\:outline-focus-ring"
  end

  private

  def render_link(current:)
    rendered.concat(nav_link_to("My tables", "/tables", current: current))
  end
end
