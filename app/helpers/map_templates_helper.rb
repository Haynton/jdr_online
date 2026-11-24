# The pages of « Mes cartes » (MapTemplatesController)
module MapTemplatesHelper
  # The grid of a map, in words: « 28 × 21 cases »
  def map_template_size(map_template)
    t("map_templates.size", columns: map_template.columns, rows: map_template.rows)
  end

  # A page of a map across the whole width (map_templates/_page). The block is captured here, while the page is still
  # the current template, so that its short translation keys (t(".title")) are looked up for the page (as auth_card)
  def map_template_page(&)
    content = capture(&)
    content_for(:full_width_page) { render("map_templates/page", content: content) }
  end
end
