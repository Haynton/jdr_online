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
  # prototype, faded while it can do nothing; narrower while it shows its icon alone (under 1536 px)
  MAP_BAR_TOOL_CLASSES = %w[
    inline-flex h-9 items-center gap-1.5 rounded-lg border border-line bg-surface px-2 text-[13px] font-semibold
    2xl:px-2.5
    text-ink transition-colors hover:bg-surface-raised aria-pressed:border-brass aria-pressed:bg-primary-soft
    aria-pressed:text-primary-soft-ink focus-visible:outline-2 focus-visible:outline-offset-2
    focus-visible:outline-focus-ring disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-surface
  ].join(" ").freeze
  # The name of a button of the bar beside its icon, from 1536 px (Anthony's request: the icons alone on a phone and
  # a smaller screen, where the bar would take several lines; with the way of making the map in the bar, the names
  # need about 1370 px), the name kept for screen readers and in the tooltip
  MAP_BAR_LABEL_CLASSES = "max-2xl:sr-only".freeze
  # A choice of the switch « Dessiner | Image » of the panel (map_templates/_making_choices), like those of the theme
  # selector: half of the switch each, ink on the field background
  MAKING_CHOICE_CLASSES = %w[
    flex h-8 flex-1 items-center justify-center gap-1.5 rounded-md px-2 text-[13px] whitespace-nowrap text-ink
    transition-colors
    has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The zone to drop the picture of a map on (the tab Image): dashed like the cards still to fill, gold while a file is
  # dragged over it
  PICTURE_DROP_ZONE_CLASSES = %w[
    grid justify-items-center gap-2 rounded-xl border-2 border-dashed border-field-line px-4 py-5 text-center
    transition-colors data-dragging:border-brass data-dragging:bg-primary-soft
  ].join(" ").freeze
  # A family of the tab Objects, a pill like the filters of « Mes tables »: tonal gold once chosen
  MAP_FAMILY_TAB_CLASSES = %w[
    h-7 flex-1 rounded-full border border-line bg-surface px-2 text-xs font-semibold text-muted transition-colors
    hover:text-ink aria-selected:border-primary-soft-ink/50 aria-selected:bg-primary-soft
    aria-selected:text-primary-soft-ink focus-visible:outline-2 focus-visible:outline-offset-2
    focus-visible:outline-focus-ring
  ].join(" ").freeze
  # A field of the bar of the editor (the name, the columns): it looks like the text around it, its frame shown only
  # when pointed at or typed in, red when refused (aria-invalid). Not a field of Simple Form: it is part of the title
  MAP_INLINE_FIELD_CLASSES = %w[
    rounded border border-transparent bg-transparent px-1 text-ink hover:border-field-line focus:border-ink
    focus:bg-field focus:outline-none aria-invalid:border-error-ink aria-invalid:bg-error-bg
  ].join(" ").freeze
  # « − » and « + » around the number of columns (and the width of a picture), 32 px
  MAP_SIZE_BUTTON_CLASSES = %w[
    flex size-8 shrink-0 items-center justify-center rounded-md border border-line bg-surface text-ink transition-colors
    hover:bg-surface-raised focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The number of columns (and the width of a picture), a field without the arrows of a number field (the buttons
  # around it do that)
  MAP_COLUMNS_FIELD_CLASSES = [
    "h-8 w-14 rounded-md border border-transparent bg-field text-center text-sm font-semibold text-ink tabular-nums",
    "hover:border-field-line focus:border-ink focus:outline-none", *CharacterSheets::FieldsHelper::NO_ARROWS_CLASSES
  ].join(" ").freeze
  # A button floating over the board (help, zoom), square with rounded corners (Anthony's request, rather than round):
  # the surface of the panels, a shadow to stand out of the map
  MAP_FLOATING_BUTTON_CLASSES = %w[
    flex size-10 items-center justify-center rounded-xl border border-line bg-surface text-ink shadow-md
    transition-colors hover:bg-surface-raised focus-visible:outline-2 focus-visible:outline-offset-2
    focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The icons of the zoom buttons, written in full: a search for a partial finds them
  ZOOM_ICON_PARTIALS = {
    "plus" => "shared/icons/plus", "minus" => "shared/icons/minus", "maximize" => "shared/icons/maximize"
  }.freeze
  # The name in the bar: a field like the others of the bar, underlined with dots while it is not typed in, so that it
  # reads as a text one can change
  MAP_NAME_FIELD_CLASSES = "#{MAP_INLINE_FIELD_CLASSES} border-b-field-line border-dashed focus:border-solid".freeze
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

  # The words of the figures of the drawing, by count (« 1 case », « 12 cases »), for the plural rules of the page
  def map_editor_figure_labels
    %i[cells walls doors objects].index_with { |figure| t("map_templates.editor.figures.#{figure}") }
  end

  # The tools of the editor, in the order of their registry: [[key, name], ...]
  def map_floor_tools
    MapFloors.keys.map { |key| [key, t("map_templates.floors.#{key}")] }
  end

  def map_edge_tools
    MapEdges.keys.map { |key| [key, t("map_templates.edges.#{key}")] }
  end

  # The objects of a family: [[key, name, size]], the size written only for an object of more than one cell (« 2×1 »)
  def map_object_tools(family)
    MapObjects.of_family(family).map do |map_object|
      size = "#{map_object.width}×#{map_object.height}" unless map_object.width * map_object.height == 1
      [map_object.key, t("map_templates.objects.#{map_object.key}"), size]
    end
  end
end
