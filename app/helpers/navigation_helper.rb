module NavigationHelper
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

  # Something waits for the user behind a link (the bell, shared/_notifications_bell): a gold dot with the number,
  # on the corner of the icon.
  # brass with page text, like the "+" of the create card. The ring of the bar color sets it apart from the icon.
  # It stays inside the link (40 px wide while folded), which cuts what overflows
  SIDE_NAV_COUNT_CLASSES = %w[
    absolute -top-1.5 -right-2 h-4 min-w-4 rounded-full bg-brass px-1 text-center text-[10px] leading-4 font-bold
    text-page ring-2 ring-surface
  ].join(" ").freeze
  # Past this, "9+": the dot keeps its size
  SIDE_NAV_COUNT_MAX = 9

  # Room left for the navigation of a signed in user: under the floating bar of a phone (56 px, 16 px above
  # the bottom, and some air), on the left from 768 px. It slides along with the width of the bar
  SIGNED_IN_SHELL_CLASSES = %w[
    pb-20 md:pb-0 md:pl-16 md:nav-expanded:pl-60
    motion-safe:md:transition-[padding] motion-safe:md:duration-200 motion-safe:md:ease-out
  ].join(" ").freeze

  # The settings window (shared/_settings_dialog), for a signed in user. Not on the settings pages:
  # they hold the frame of the same name themselves, and "Settings" there simply leads to the page
  def settings_dialog_available?
    user_signed_in? && !settings_page?
  end

  # "Settings" of the navigation loads the section into the settings window when there is one.
  # No prefetch: its answer, laid out for the window, would be reused for the same address opened as a page
  def settings_link_data
    settings_dialog_available? ? { turbo_frame: "settings_dialog", turbo_prefetch: false } : {}
  end

  def nav_icon(icon)
    render("shared/icons/#{icon}", css_class: NAV_ICON_CLASSES)
  end

  # title: the label as a tooltip, for a mouse user while only the icon shows. data: optional (settings_link_data)
  def side_nav_link_to(label, path, icon:, current: current_page?(path), data: {})
    link_to path, class: SIDE_NAV_LINK_CLASSES, title: label, aria: current_page_aria(current), data: data do
      side_nav_item_content(label, icon)
    end
  end

  def side_nav_count(count)
    shown_count = count > SIDE_NAV_COUNT_MAX ? "#{SIDE_NAV_COUNT_MAX}+" : count
    tag.span(shown_count, class: SIDE_NAV_COUNT_CLASSES, aria: { hidden: true })
  end

  # A form button of the side navigation (log out), shaped like its links. A <button> takes the width of its content,
  # where a link stretches: it gets the width of the bar less its 12 px margins, so that its hover fills the row
  # confirm: a question asked first (shared/_confirm_dialog), nothing is sent if the user cancels;
  # its confirm button says the label of this button
  def side_nav_button_to(label, path, icon:, method:, confirm: nil)
    button_to path, method: method, class: "#{SIDE_NAV_LINK_CLASSES} md:w-[calc(100%-1.5rem)]", title: label,
                    form: { data: confirm ? { turbo_confirm: confirm, confirm_button: label } : {} } do
      side_nav_item_content(label, icon)
    end
  end

  def side_nav_item_content(label, icon)
    nav_icon(icon) + tag.span(label, class: SIDE_NAV_LABEL_CLASSES)
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

  # The list of the templates and the page of one of them
  def sheet_templates_page?
    controller_path.start_with?("sheet_templates")
  end

  # The list of the characters and the page of one of them (not the creation steps, under the table)
  def characters_page?
    controller_path == "characters"
  end

  # The list of the maps and the page of one of them
  def map_templates_page?
    controller_path.start_with?("map_templates")
  end

  # Tells screen readers which link leads to the page being shown
  def current_page_aria(current)
    current ? { current: "page" } : {}
  end
end
