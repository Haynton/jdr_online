module NavigationHelper
  # On surface-raised, only ink stays readable (muted falls under 4.5)
  NAV_ITEM_CLASSES = %w[
    flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-[15px] text-ink whitespace-nowrap transition-colors
    hover:bg-surface-raised
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  NAV_ICON_CLASSES = "size-5 shrink-0".freeze

  # A link of a navigation menu, with its icon. The page being shown has no color of its own (decision:
  # the green background looked like a selected option), screen readers still hear it through aria-current.
  # current: replaces the URL check when one page has several URLs
  def nav_link_to(label, path, icon:, current: current_page?(path))
    link_to path, class: NAV_ITEM_CLASSES, aria: current_page_aria(current) do
      nav_icon(icon) + label
    end
  end

  # Also used by the log out button of the menu, so that it looks like the links around it
  def nav_item_classes
    NAV_ITEM_CLASSES
  end

  def nav_icon(icon)
    render("shared/icons/#{icon}", css_class: NAV_ICON_CLASSES)
  end

  # Tells screen readers which link leads to the page being shown
  def current_page_aria(current)
    current ? { current: "page" } : {}
  end
end
