module SettingsHelper
  # On a phone, each section is a full width row of a list, with a chevron (taller, for a finger).
  # From 768 px, a link of the side menu, with tight padding, like the settings of the Claude app
  SETTINGS_LINK_BASE_CLASSES = %w[
    flex items-center justify-between gap-3 px-4 py-3 text-base whitespace-nowrap transition-colors
    md:px-3 md:py-1.5 md:text-[15px]
    hover:bg-surface-raised hover:text-ink md:rounded-lg
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  # The current section is only shown on a wide screen: in the phone list, no section is open.
  # On surface-raised, only ink stays readable (muted falls under 4.5)
  SETTINGS_LINK_STATE_CLASSES = {
    current: "text-ink md:bg-surface-raised",
    other: "text-ink md:text-muted"
  }.freeze

  # The controllers that show each section, its form included when it comes back with an error
  SETTINGS_SECTION_CONTROLLERS = {
    display: %w[displays sections],
    account: %w[accounts avatars usernames emails],
    security: %w[securities passwords],
    legal_notice: %w[legal_notices]
  }.freeze

  def current_settings_section?(section)
    controller_name.in?(SETTINGS_SECTION_CONTROLLERS.fetch(section))
  end

  # A section of the settings (the menu around it comes from layouts/settings).
  # Like page_header, the block is captured here so that its short translation keys stay the page's ones
  def settings_section(title:, &)
    render "settings/section", title: title, content: capture(&)
  end

  # A group of setting rows under a small capitals heading ("THEME")
  def settings_group(title:, &)
    render "settings/group", title: title, rows: capture(&)
  end

  # One setting: label and description on the left, the control (block) on the right.
  # label_id lets the control name itself with aria-labelledby
  def setting_row(label:, label_id:, description: nil, &)
    render "settings/row", label: label, label_id: label_id, description: description, control: capture(&)
  end

  # In the settings window, settings_dialog_link_to (SettingsDialogHelper) draws it instead
  def settings_link_to(label, path, current: current_page?(path))
    return settings_dialog_link_to(label, path, current: current) if settings_in_dialog?

    state = current ? :current : :other
    link_to path, class: "#{SETTINGS_LINK_BASE_CLASSES} #{SETTINGS_LINK_STATE_CLASSES.fetch(state)}",
                  aria: current_page_aria(current) do
      safe_join([label, settings_link_chevron])
    end
  end

  # "›" at the end of a row of the phone list (the chevron down, turned)
  def settings_link_chevron
    render("shared/icons/chevron_down", css_class: "size-4 shrink-0 -rotate-90 text-muted md:hidden")
  end

  # On a phone, /settings only shows the list of sections, and a section page only its section.
  # Not in the settings window, which keeps both side by side at any width: a narrow window hid the menu
  # and squeezed the section into its 220 px column
  def settings_menu_visibility_classes
    return "" if settings_in_dialog?

    sections_list_page? ? "" : "hidden md:block"
  end

  def settings_section_visibility_classes
    return "" if settings_in_dialog?

    sections_list_page? ? "hidden md:block" : ""
  end
end
