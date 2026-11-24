# What the map editor reads from the page (map_editor_controller.js) and how its panel opens: the drawing and the
# picture of the map, its texts, the way it is made, the maps ready to use (MapPresets). The look of the editor (the
# classes of its tools, its bar): MapTemplatesHelper
module MapEditorHelper
  # The size of a cell of a drawn map, in units of its SVG (map_editor/square_grid.js, cellSize)
  MAP_CELL_SIZE = 24

  # What the editor reads of a map ready to use (map_templates/_preset_tools): the size of its grid and its drawing,
  # like an undo step of the editor (map_editor/map_layout.js#snapshot)
  def map_preset_data(preset)
    { columns: preset.columns, rows: preset.rows, layout: preset.layout }.to_json
  end

  # Its whole grid in its preview
  def map_preset_view_box(preset)
    "0 0 #{preset.columns * MAP_CELL_SIZE} #{preset.rows * MAP_CELL_SIZE}"
  end

  # How the map is made: drawn, or played on a picture of one's own (its layout says so)
  def map_making_mode(map_template)
    map_template.layout_in_database["mode"] || "draw"
  end

  def map_picture_mode?(map_template)
    map_making_mode(map_template) == "picture"
  end

  # The tab shown first in the panel: the templates on a map still empty (a good start), the floors otherwise
  def map_editor_first_tab_index(map_template)
    map_template.layout_in_database.values_at("floors", "edges", "objects").all?(&:blank?) ? 0 : 1
  end

  # The editor works on a map of « Mes cartes » or on its copy in a table (GameMap): the same drawing, the same
  # picture, at their own addresses (a map of a table under its table)
  def map_editor_record(map)
    map.is_a?(GameMap) ? [map.game_table, map] : [map]
  end

  # The brush « Zones bloquantes »: a map of a table only, where tokens will move (MapPassage)
  def map_editor_blocking?(map)
    map.is_a?(GameMap)
  end

  # What the map editor needs (map_editor_controller.js): the drawing, the grid, where to save it, its texts
  def map_editor_data(map_template)
    { controller: "map-editor", action: "turbo:morph@document->map-editor#drawEverything",
      map_editor_layout_value: map_template.layout_in_database.to_json,
      map_editor_columns_value: map_template.columns, map_editor_rows_value: map_template.rows,
      map_editor_url_value: polymorphic_path([*map_editor_record(map_template), :layout]),
      map_editor_figure_labels_value: map_editor_figure_labels.to_json,
      map_editor_picture_url_value: map_picture_url(map_template), **map_editor_texts }
  end

  # A preview on its card of « Mes cartes »: something drawn, or its picture; a map still empty keeps its icon
  def map_preview?(map_template)
    return map_template.picture.attached? if map_picture_mode?(map_template)

    map_template.layout_in_database.values_at("floors", "edges", "objects").any?(&:present?)
  end

  # What the preview draws (map_preview_controller.js): the drawing, the grid, the picture
  def map_preview_data(map_template)
    { controller: "map-preview", map_preview_layout_value: map_template.layout_in_database.to_json,
      map_preview_columns_value: map_template.columns, map_preview_rows_value: map_template.rows,
      map_preview_picture_url_value: map_picture_url(map_template) }
  end

  # Its whole grid in its preview
  def map_template_view_box(map_template)
    "0 0 #{map_template.columns * MAP_CELL_SIZE} #{map_template.rows * MAP_CELL_SIZE}"
  end

  # The picture of a map played on a picture of one's own, nothing when it has none yet
  def map_picture_url(map_template)
    url_for(map_template.picture) if map_template.picture.attached?
  end

  # The texts the editor writes or asks: the number of degrees and the time are written by the page, in the place of
  # their marks
  def map_editor_texts
    { map_editor_save_failed_message_value: t("map_templates.editor.save_failed"),
      map_editor_rotation_label_value: t("map_templates.editor.rotate", degrees: "__degrees__"),
      map_editor_saving_label_value: t("map_templates.editor.saving"),
      map_editor_saved_label_value: t("map_templates.editor.saved", time: "__time__"),
      map_editor_shrink_question_value: t("map_templates.editor.shrink_question"),
      map_editor_clear_question_value: t("map_templates.editor.clear_question"),
      map_editor_replace_question_value: t("map_templates.preset_tools.replace_question", name: "__name__") }
  end
end
