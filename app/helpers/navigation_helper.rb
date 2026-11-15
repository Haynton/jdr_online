module NavigationHelper
  NAV_LINK_BASE_CLASSES = %w[
    rounded-lg px-3 py-2 text-[15px] whitespace-nowrap transition-colors
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  # On surface-raised, only ink stays readable (muted falls under 4.5): the hover turns the text to ink
  NAV_LINK_STATE_CLASSES = {
    current: "bg-primary-soft font-semibold text-primary-soft-ink",
    other: "text-muted hover:bg-surface-raised hover:text-ink"
  }.freeze

  # A link of the navbar. The page being shown is marked for everyone: green background on screen,
  # aria-current for screen readers. current: replaces the URL check when one page has several URLs
  def nav_link_to(label, path, current: current_page?(path))
    state = current ? :current : :other
    link_to label, path,
            class: "#{NAV_LINK_BASE_CLASSES} #{NAV_LINK_STATE_CLASSES.fetch(state)}",
            aria: current_page_aria(current)
  end

  # Tells screen readers which link leads to the page being shown
  def current_page_aria(current)
    current ? { current: "page" } : {}
  end
end
