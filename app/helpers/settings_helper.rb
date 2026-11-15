module SettingsHelper
  SETTINGS_LINK_BASE_CLASSES = %w[
    block rounded-lg px-4 py-3 text-base whitespace-nowrap transition-colors
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  # On surface-raised, only ink stays readable (muted falls under 4.5)
  SETTINGS_LINK_STATE_CLASSES = {
    current: "bg-surface-raised text-ink",
    other: "text-muted hover:bg-surface-raised hover:text-ink"
  }.freeze

  # The settings panel: section menu on the left, the section on the right.
  # Like page_header, the block is captured here so that its short translation keys stay the page's ones
  def settings_panel(section_title:, &)
    render "settings/panel", section_title: section_title, content: capture(&)
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

  def settings_link_to(label, path, current: current_page?(path))
    state = current ? :current : :other
    link_to label, path, class: "#{SETTINGS_LINK_BASE_CLASSES} #{SETTINGS_LINK_STATE_CLASSES.fetch(state)}",
                         aria: current_page_aria(current)
  end
end
