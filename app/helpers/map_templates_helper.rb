# The pages of « Mes cartes » (MapTemplatesController)
module MapTemplatesHelper
  # A tool of the map editor: its frame, the gold of a chosen card once pressed (only ink on primary-soft)
  MAP_TOOL_CLASSES = %w[
    flex w-full items-center gap-2 rounded-lg bg-surface px-2 py-1.5 text-left text-sm text-ink ring-1 ring-line
    transition-colors hover:bg-surface-raised aria-pressed:bg-primary-soft aria-pressed:ring-2 aria-pressed:ring-brass
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

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

  # What the map editor needs (map_editor_controller.js): the drawing, the grid, where to save it
  def map_editor_data(map_template)
    { controller: "map-editor",
      map_editor_layout_value: map_template.layout_in_database.to_json,
      map_editor_columns_value: map_template.columns, map_editor_rows_value: map_template.rows,
      map_editor_url_value: map_template_layout_path(map_template),
      map_editor_save_failed_message_value: t("map_templates.editor.save_failed") }
  end

  # The tools of the editor, in the order of their registry: [[key, name], ...]
  def map_floor_tools
    MapFloors.keys.map { |key| [key, t("map_templates.floors.#{key}")] }
  end

  def map_edge_tools
    MapEdges.keys.map { |key| [key, t("map_templates.edges.#{key}")] }
  end
end
