module NavigationHelper
  # On surface-raised, only ink stays readable (muted falls under 4.5)
  NAV_ITEM_CLASSES = %w[
    flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-[15px] text-ink whitespace-nowrap transition-colors
    hover:bg-surface-raised
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  NAV_ICON_CLASSES = "size-5 shrink-0".freeze

  # A link of the side navigation. On a phone, a round icon of the floating bar.
  # From 768 px, a row: icon alone while the navigation is folded, icon and label once unfolded.
  # The page being shown gets surface-raised, like the current section of the settings
  SIDE_NAV_LINK_CLASSES = %w[
    flex size-11 items-center justify-center rounded-full text-ink transition-colors
    md:mx-3 md:size-auto md:h-10 md:justify-start md:gap-3 md:overflow-hidden md:rounded-lg md:px-2.5
    hover:bg-surface-raised aria-[current=page]:bg-surface-raised
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  # A text of the side navigation (labels, logo name, username). From 768 px it is always there, on one line,
  # cut by the edge of its link while the bar is folded, and fades in once the bar has widened: switching
  # from sr-only to not-sr-only made it wrap onto two lines while the bar was opening.
  # Transparent, it is still read by screen readers. On a phone (max-md), only screen readers get it
  SIDE_NAV_FADING_TEXT_CLASSES = %w[
    whitespace-nowrap max-md:sr-only
    md:opacity-0 md:nav-expanded:opacity-100
    motion-safe:md:transition-opacity motion-safe:md:duration-200 motion-safe:md:nav-expanded:delay-100
  ].join(" ").freeze

  SIDE_NAV_LABEL_CLASSES = "text-[15px] #{SIDE_NAV_FADING_TEXT_CLASSES}".freeze

  # Room left for the navigation of a signed in user: under the floating bar of a phone (56 px, 16 px above
  # the bottom, and some air), on the left from 768 px. It slides along with the width of the bar
  SIGNED_IN_SHELL_CLASSES = %w[
    pb-20 md:pb-0 md:pl-16 md:nav-expanded:pl-60
    motion-safe:md:transition-[padding] motion-safe:md:duration-200 motion-safe:md:ease-out
  ].join(" ").freeze

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

  # title: the label as a tooltip, for a mouse user while only the icon shows
  def side_nav_link_to(label, path, icon:, current: current_page?(path))
    link_to path, class: SIDE_NAV_LINK_CLASSES, title: label, aria: current_page_aria(current) do
      nav_icon(icon) + tag.span(label, class: SIDE_NAV_LABEL_CLASSES)
    end
  end

  def side_nav_fading_text_classes
    SIDE_NAV_FADING_TEXT_CLASSES
  end

  def page_shell_classes
    user_signed_in? ? SIGNED_IN_SHELL_CLASSES : ""
  end

  # The name of the logo always stays in the page, so that a logo link keeps its name for screen readers.
  # compact_on_phone: only the d20 on a phone. with_side_nav: only the d20 while the side navigation is folded
  def logo_name_visibility_classes(options)
    return SIDE_NAV_FADING_TEXT_CLASSES if options[:with_side_nav]
    return "sr-only sm:not-sr-only" if options[:compact_on_phone]

    ""
  end

  # The logo leads a signed in user to their tables, a visitor to the home page
  def logo_path
    user_signed_in? ? game_tables_path : root_path
  end

  # Tells screen readers which link leads to the page being shown
  def current_page_aria(current)
    current ? { current: "page" } : {}
  end
end
