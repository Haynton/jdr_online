module ThemesHelper
  # The three theme choices and their icon
  THEME_CHOICE_ICONS = { "light" => "sun", "dark" => "moon", "system" => "monitor" }.freeze

  # Named by the visible label of its row when there is one (settings), by "Theme" otherwise
  # (navbar of the visitors, sign in pages)
  def theme_selector_aria(labelled_by)
    labelled_by ? { labelledby: labelled_by } : { label: t("shared.theme_selector.label") }
  end

  # The compact selector only shows the icons: the text stays for screen readers
  def theme_choice_text_classes(compact)
    compact ? "sr-only" : ""
  end
end
