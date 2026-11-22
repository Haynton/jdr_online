# The pages of the templates of a game master: "My templates" (laid out like the first step of the creation of a
# table, rows of cards, decision: not like "My tables", so that the two lists are not mixed up) and the template
# editor (laid out like the pages of a creation: the band of its steps, the buttons at the bottom right)
module SheetTemplatesHelper
  # A card of a template: the gold scroll of the cards of templates of the creation of a table (until the game
  # master uploads its picture), its name, what it holds. A link to its page for one of mine: gold outline on hover
  TEMPLATE_TILE_CLASSES = "relative flex h-full flex-col overflow-hidden rounded-xl bg-surface ring-1 ring-line".freeze
  TEMPLATE_LINK_TILE_CLASSES = %w[
    flex h-full flex-col overflow-hidden rounded-xl bg-surface ring-1 ring-line transition-shadow hover:ring-2
    hover:ring-brass focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The partial of each icon a template may show (SheetTemplate::ICONS), written in full: a search for a partial finds
  # who draws it
  ICON_PARTIALS = {
    "scroll_text" => "shared/icons/scroll_text", "swords" => "shared/icons/swords", "castle" => "shared/icons/castle",
    "crown" => "shared/icons/crown", "shield" => "shared/icons/shield", "wand_sparkles" => "shared/icons/wand_sparkles",
    "flame" => "shared/icons/flame", "skull" => "shared/icons/skull", "ghost" => "shared/icons/ghost",
    "moon_star" => "shared/icons/moon_star", "rocket" => "shared/icons/rocket", "bot" => "shared/icons/bot"
  }.freeze
  # The classes of each color of banner (SheetTemplate::BANNER_COLORS), written in full for Tailwind: its background,
  # its accent (eyebrow, large icon, "See more"), and the pill of its choice, filled with the accent (the pale
  # background would not stand out from the page: 1.2, under the shape contrast of 3; the accent reaches 7 to 10)
  BANNER_CLASSES = {
    "gold" => { background: "bg-primary-soft", accent: "text-primary-soft-ink", swatch: "bg-primary-soft-ink" },
    "crimson" => { background: "bg-banner-crimson", accent: "text-banner-crimson-ink",
                   swatch: "bg-banner-crimson-ink" },
    "forest" => { background: "bg-banner-forest", accent: "text-banner-forest-ink", swatch: "bg-banner-forest-ink" },
    "night" => { background: "bg-banner-night", accent: "text-banner-night-ink", swatch: "bg-banner-night-ink" },
    "arcane" => { background: "bg-banner-arcane", accent: "text-banner-arcane-ink", swatch: "bg-banner-arcane-ink" },
    "stone" => { background: "bg-banner-stone", accent: "text-banner-stone-ink", swatch: "bg-banner-stone-ink" }
  }.freeze
  # A pill of the choice of the icon: the field color at rest, gold tonal with a gold ring once chosen, the focus
  # outline from the keyboard (the radio button before it is its peer)
  ICON_CHOICE_CLASSES = %w[
    flex size-9 cursor-pointer items-center justify-center rounded-full bg-field text-ink transition-colors
    hover:bg-surface-raised peer-checked:bg-primary-soft peer-checked:text-primary-soft-ink peer-checked:ring-2
    peer-checked:ring-brass peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2
    peer-focus-visible:outline-focus-ring
  ].join(" ").freeze
  # A pill of the choice of the color of the banner: filled with the accent of the color (BANNER_CLASSES :swatch), the
  # one chosen ringed in ink, away from it (ring-offset of the page)
  COLOR_CHOICE_CLASSES = %w[
    block size-9 cursor-pointer rounded-full transition-shadow peer-checked:ring-2 peer-checked:ring-ink
    peer-checked:ring-offset-2 peer-checked:ring-offset-page peer-focus-visible:outline-2
    peer-focus-visible:outline-offset-4 peer-focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The steps of the editor, in order; those not made yet are marked as coming soon in the band. The creation path (its
  # steps, their sections and fields) comes right after the informations (decision: one step for the steps and the
  # fields of a duplicated template, whose steps stay as they are)
  EDITOR_STEPS = %i[informations creation_path catalog].freeze
  COMING_EDITOR_STEPS = %i[catalog].freeze

  # The icon of a template (the scroll for an unknown one), decorative: its name says the template
  def sheet_template_icon(icon, css_class:)
    render ICON_PARTIALS.fetch(icon, ICON_PARTIALS["scroll_text"]), css_class: css_class
  end

  # The classes of one part of the banner of a template (:background, :accent, :swatch), gold for an unknown color
  def banner_classes(banner_color, part)
    BANNER_CLASSES.fetch(banner_color, BANNER_CLASSES["gold"]).fetch(part)
  end

  # "Épées croisées", for the choice of the icon
  def sheet_template_icon_label(icon)
    t("sheet_templates.icons.#{icon}")
  end

  # "D'après « Fantasy héroïque »", nil for a template made from nothing (or whose original was deleted)
  def sheet_template_origin(sheet_template)
    t("sheet_templates.contents.from", name: sheet_template.parent.name) if sheet_template.parent
  end

  # A page of the template editor: the band of its steps across the whole width, then the page (steps_page).
  # flush_top: the content touches the band (the banner of the page Informations)
  def template_editor_page(sheet_template:, current_step:, flush_top: false, &)
    band = render("shared/steps_band", steps: template_editor_steps(sheet_template, current_step),
                                       label: t("sheet_templates.editor.band_label"))
    steps_page(band: band, flush_top: flush_top, &)
  end

  # The figures of the banner of the page Informations, as small boxes: [[label, value]]. The fields, the creation
  # steps (or the single page of a template without steps), then each kind of its catalog (CatalogEntry::KINDS)
  def sheet_template_figures(sheet_template)
    character_fields = sheet_template.character_fields.to_h
    [[t("sheet_templates.figures.fields"), character_fields["fields"].to_a.size],
     sheet_template_steps_figure(character_fields["creation_steps"].to_a.size),
     *sheet_template_catalog_figures(sheet_template)]
  end

  # A template without steps asks its whole sheet on a single page
  def sheet_template_steps_figure(step_count)
    return [t("sheet_templates.figures.single_page"), 1] if step_count.zero?

    [t("sheet_templates.figures.steps"), step_count]
  end

  def sheet_template_catalog_figures(sheet_template)
    counts = sheet_template.catalog_entries.group(:kind).count
    CatalogEntry::KINDS.filter_map { |kind| [t("sheet_templates.figures.#{kind}"), counts[kind]] if counts[kind] }
  end

  # The tables that use the template (its tables read its catalog), the newest first
  def sheet_template_tables(sheet_template)
    sheet_template.game_tables.order(created_at: :desc)
  end

  # Each step of the editor: the steps made open their page from anywhere (the editor is not a path to follow), the
  # others are coming soon
  def template_editor_steps(sheet_template, current_step)
    EDITOR_STEPS.each_with_index.map do |step, index|
      { key: step, number: index + 1, label: t("sheet_templates.editor.steps.#{step}"),
        state: template_editor_step_state(step, current_step),
        path: (template_editor_step_path(sheet_template, step) if template_editor_step_open?(step, current_step)) }
    end
  end

  private

  def template_editor_step_state(step, current_step)
    return :coming_soon if COMING_EDITOR_STEPS.include?(step)

    step == current_step ? :current : :upcoming
  end

  def template_editor_step_open?(step, current_step)
    step != current_step && COMING_EDITOR_STEPS.exclude?(step)
  end

  def template_editor_step_path(sheet_template, step)
    { informations: sheet_template_path(sheet_template),
      creation_path: sheet_template_fields_path(sheet_template) }.fetch(step)
  end
end
