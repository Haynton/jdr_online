# The choices of the first step of the creation of a table: rows of tiles for the covers (filtered by theme)
# and the sheet templates (game_tables/_choice_row, game_tables/_details_form)
module GameTableChoicesHelper
  # A choice drawn as a tile: its radio button is hidden from sight but still focused and read (sr-only, peer),
  # the tile right after it shows the state: gold outline when chosen, focus outline from the keyboard,
  # red outline once refused. The chosen tile keeps its gold outline under the mouse and after a refusal
  # (hover and aria-invalid come later in the CSS: without the last two classes, they won)
  CHOICE_TILE_CLASSES = %w[
    block h-full cursor-pointer overflow-hidden rounded-xl bg-surface ring-1 ring-line transition-shadow
    hover:ring-field-line peer-checked:ring-2 peer-checked:ring-brass
    peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-focus-ring
    peer-aria-invalid:ring-error-ink
    peer-checked:hover:ring-brass peer-checked:peer-aria-invalid:ring-brass
  ].join(" ").freeze

  # The check in the corner of the chosen tile: a sibling of the radio button too, shown once it is checked
  CHOICE_CHECK_CLASSES = %w[
    pointer-events-none absolute top-2 right-2 hidden size-6 items-center justify-center rounded-full
    bg-brass text-page peer-checked:flex
  ].join(" ").freeze

  # The card that leads to the template builder, first of the row of templates: drawn like the empty spots of
  # "My tables" (dashed border), not as a choice
  CREATE_TEMPLATE_CARD_CLASSES = %w[
    flex h-full min-h-52 flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-field-line
    bg-surface p-4 text-center text-ink transition-colors hover:bg-surface-raised
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  def choice_tile_classes
    CHOICE_TILE_CLASSES
  end

  def choice_check_classes
    CHOICE_CHECK_CLASSES
  end

  def create_template_card_classes
    CREATE_TEMPLATE_CARD_CLASSES
  end

  # A group of tiles has no Simple Form wrapper: its legend and its error reuse the classes of the fields
  def choice_legend_classes
    SimpleFormFieldClasses::LABEL
  end

  def choice_error_classes
    SimpleFormFieldClasses::ERROR
  end

  # The template is required: once refused, its radio buttons are marked invalid and point to the message
  def sheet_template_choice_aria(game_table)
    return {} unless game_table.errors.include?(:sheet_template)

    { invalid: true, describedby: "sheet-template-error" }
  end

  def cover_choice_label(cover_image)
    t("game_tables.covers.#{cover_image}")
  end

  # A row of choices filtered by pills: the filter controller of "My tables", and the arrows recounted after a filter
  def choice_row_data(filterable:)
    return { controller: "card-row" } unless filterable

    { controller: "card-row table-filter", action: "table-filter:changed->card-row#toggleButtons" }
  end

  # The hint leaves room on its right for what sits at the top right of the row: the arrows alone (from 768 px),
  # or the pills and the arrows (from 1024 px)
  def choice_row_hint_classes(filterable:)
    filterable ? "max-w-xl text-xs text-muted lg:max-w-[calc(100%-26rem)]" : "max-w-xl text-xs text-muted md:pr-24"
  end

  def choice_row_controls_classes(filterable:)
    return "absolute top-0 right-0" unless filterable

    "mt-3 flex items-center gap-4 lg:absolute lg:top-0 lg:right-0 lg:mt-0"
  end

  # One pill per theme of the covers (GameTable::COVER_THEMES), in the "theme" group
  def cover_filters
    GameTable::COVER_THEME_NAMES.map do |theme|
      { group: "theme", value: theme, label: t("game_tables.cover_themes.#{theme}") }
    end
  end

  # Read by table_filter_controller.js to show or hide the cover
  def cover_card_filter_data(cover_image)
    { table_filter_target: "card", theme: GameTable::COVER_THEMES.fetch(cover_image) }
  end
end
