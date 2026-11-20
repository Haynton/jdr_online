# The settings pages drawn either as a page or inside the settings window (shared/_settings_dialog).
# The server chooses: a request for the window names its frame (Turbo-Frame header). Classes for the browser
# (in-[dialog]:) were set aside: without any weight, they could lose against the spacing of the page
module SettingsDialogHelper
  # The page: menu and card centered in 1120 px. The window, like the settings of the Claude app: under its title bar,
  # two columns of the same color split by a line, the menu without its title (the bar shows it) on the left,
  # the section on the right, which scrolls as a whole. Both columns at any width of the window
  SETTINGS_LAYOUT_CLASSES = {
    page: {
      grid: %w[
        mx-auto max-w-[1120px] px-4 py-8 sm:px-8
        md:grid md:grid-cols-[240px_1fr] md:items-start md:gap-8 md:py-10
      ].join(" "),
      menu: "",
      menu_title: "text-2xl font-bold text-ink md:px-3 md:text-xl",
      menu_list: %w[
        mt-4 divide-y divide-line overflow-hidden rounded-xl border border-line bg-surface
        md:mt-3 md:space-y-1 md:divide-y-0 md:rounded-none md:border-0 md:bg-transparent
      ].join(" "),
      main: "min-w-0"
    },
    dialog: {
      grid: "grid h-full grid-cols-[180px_1fr] sm:grid-cols-[220px_1fr]",
      menu: "border-r border-line px-3 py-4",
      menu_title: "hidden",
      menu_list: "space-y-1",
      main: "flex min-h-0 min-w-0 flex-col"
    }
  }.freeze

  # The section: a card on the page, its title in a header over a line. In the window, no card and no header line:
  # the title, then the groups of rows, all scrolling together
  SETTINGS_SECTION_CLASSES = {
    page: {
      section: "rounded-xl border border-line bg-surface",
      header: "border-b border-line px-6 py-5 sm:px-8",
      title: "text-2xl font-bold text-ink",
      body: "px-6 pb-6 sm:px-8"
    },
    dialog: {
      section: "min-h-0 flex-1 overflow-y-auto px-8 py-6",
      header: "",
      title: "text-lg font-semibold text-ink",
      body: ""
    }
  }.freeze

  # A section link of the window: the wide screen look at any width, no chevron (it is not a phone list)
  DIALOG_LINK_BASE_CLASSES = %w[
    flex items-center gap-3 rounded-lg px-3 py-1.5 text-[15px] whitespace-nowrap transition-colors
    hover:bg-surface-raised hover:text-ink
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  # On surface-raised, only ink stays readable (muted falls under 4.5)
  DIALOG_LINK_STATE_CLASSES = {
    current: "bg-surface-raised text-ink",
    other: "text-muted"
  }.freeze

  def settings_in_dialog?
    turbo_frame_request_id == "settings_dialog"
  end

  # In the window, links and forms stay in the frame; on the page, they change the whole page (and its address)
  def settings_frame_target
    settings_in_dialog? ? nil : "_top"
  end

  def settings_layout_classes(part)
    SETTINGS_LAYOUT_CLASSES.fetch(settings_display_mode).fetch(part)
  end

  def settings_section_classes(part)
    SETTINGS_SECTION_CLASSES.fetch(settings_display_mode).fetch(part)
  end

  def settings_dialog_link_to(label, path, current:)
    state_classes = DIALOG_LINK_STATE_CLASSES.fetch(current ? :current : :other)
    link_to label, path, class: "#{DIALOG_LINK_BASE_CLASSES} #{state_classes}", aria: current_page_aria(current)
  end

  def settings_display_mode
    settings_in_dialog? ? :dialog : :page
  end
end
