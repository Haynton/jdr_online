# The pages of « Mes cartes » (MapTemplatesController) and the map editor
module MapTemplatesHelper
  # A tool of the panel of the editor, a tile like those of the prototype: once pressed, the gold of a chosen card
  # (only primary-soft-ink on primary-soft: 6.05 and 8.24)
  MAP_TOOL_CLASSES = %w[
    block w-full rounded-[10px] border border-line bg-surface px-0.5 pt-1.5 pb-1 text-center text-[10.5px] leading-tight
    text-ink transition-colors hover:bg-surface-raised aria-pressed:border-brass aria-pressed:bg-primary-soft
    aria-pressed:font-semibold aria-pressed:text-primary-soft-ink aria-pressed:ring-1 aria-pressed:ring-brass
    aria-pressed:ring-inset focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze
  # A button of the bar on top of the editor (undo, the eraser, zoom): 36 px high like the buttons of the bar of the
  # prototype, faded while it can do nothing
  MAP_BAR_TOOL_CLASSES = %w[
    inline-flex h-9 items-center gap-1.5 rounded-lg border border-line bg-surface px-2.5 text-[13px] font-semibold
    text-ink transition-colors hover:bg-surface-raised aria-pressed:border-brass aria-pressed:bg-primary-soft
    aria-pressed:text-primary-soft-ink focus-visible:outline-2 focus-visible:outline-offset-2
    focus-visible:outline-focus-ring disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-surface
  ].join(" ").freeze
  # A tab of the panel of the editor: its name in muted, ink and a line of brass under it once chosen
  MAP_TAB_CLASSES = %w[
    flex-1 border-b-2 border-transparent px-0.5 py-2 text-[12.5px] font-semibold text-muted transition-colors
    hover:text-ink aria-selected:border-brass aria-selected:text-ink focus-visible:outline-2
    focus-visible:outline-offset-2 focus-visible:outline-focus-ring
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

  # What the map editor needs (map_editor_controller.js): the drawing, the grid, where to save it, its texts
  def map_editor_data(map_template)
    { controller: "map-editor", action: "turbo:morph@document->map-editor#drawEverything",
      map_editor_layout_value: map_template.layout_in_database.to_json,
      map_editor_columns_value: map_template.columns, map_editor_rows_value: map_template.rows,
      map_editor_url_value: map_template_layout_path(map_template),
      map_editor_save_failed_message_value: t("map_templates.editor.save_failed"),
      map_editor_figure_labels_value: map_editor_figure_labels.to_json }
  end

  # The words of the figures of the drawing, by count (« 1 case », « 12 cases »), for the plural rules of the page
  def map_editor_figure_labels
    %i[cells walls doors].index_with { |figure| t("map_templates.editor.figures.#{figure}") }
  end

  # The tools of the editor, in the order of their registry: [[key, name], ...]
  def map_floor_tools
    MapFloors.keys.map { |key| [key, t("map_templates.floors.#{key}")] }
  end

  def map_edge_tools
    MapEdges.keys.map { |key| [key, t("map_templates.edges.#{key}")] }
  end
end
