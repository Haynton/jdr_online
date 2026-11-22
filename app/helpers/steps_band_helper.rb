# The page of a creation in steps (a table: GameTableCreationHelper, a character: CharacterCreationHelper): the band
# of the steps across the whole width (shared/_steps_band), then the content (game_tables/_creation_page)
module StepsBandHelper
  # Tonal colors only: a filled plaque is kept for buttons
  STEP_MARKER_CLASSES = {
    # A thin ring in the color of the check, as on the GM badge: the tonal background alone barely showed on the band
    done: "bg-primary-soft text-primary-soft-ink ring-1 ring-inset ring-primary-soft-ink/50",
    current: "bg-primary-soft text-primary-soft-ink ring-2 ring-primary-soft-ink",
    upcoming: "border border-field-line text-muted",
    coming_soon: "border border-dashed border-field-line text-muted"
  }.freeze

  # The page around a step: band, the rendered band of the steps; the block is captured here, while the page is
  # still the current template, so that its short translation keys (t(".title")) are looked up for the page and
  # not for the partial (same as auth_card). flush_top: the content touches the band (a cover from edge to edge)
  def steps_page(band:, flush_top: false, &)
    content = capture(&)
    content_for(:full_width_page) do
      render "game_tables/creation_page", band: band, flush_top: flush_top, content: content
    end
  end

  def creation_main_classes(flush_top)
    flush_top ? "px-4 pb-12 sm:px-8" : "px-4 pt-8 pb-12 sm:px-8"
  end

  # A link looks like one: its label in ink, "Change" or "Open" under it in the color of links, a background
  # when hovered (only ink on surface-raised: muted falls under 4.5 in the light theme). The negative margins keep
  # the marker in line with the other steps; wider on the right, where the label would touch the edge
  def step_link_classes(step)
    return "flex items-center gap-2" unless step[:path]

    "-my-1.5 -ml-1.5 flex items-center gap-2 rounded-lg py-1.5 pr-3 pl-1.5 hover:bg-surface-raised"
  end

  def step_label_classes(step)
    return "font-semibold text-ink" if step[:state] == :current
    return "text-ink max-sm:sr-only" if step[:path]

    "text-muted max-sm:sr-only"
  end

  # Under the label: "Change" for a step done, "Open" for a later one reached already, "Soon" for a later milestone
  def step_note(step)
    return t("shared.steps_band.coming_soon") if step[:state] == :coming_soon
    return unless step[:path]

    t(step[:state] == :done ? "shared.steps_band.change" : "shared.steps_band.open")
  end

  def step_note_classes(step)
    step[:path] ? "block text-xs font-medium text-link" : "block text-xs"
  end

  def step_marker_classes(state)
    STEP_MARKER_CLASSES.fetch(state)
  end

  def step_aria(state)
    state == :current ? { current: "step" } : {}
  end

  # The state of a step for the one being filled in: done before it, upcoming after it
  def step_state(index, current_index)
    return :current if index == current_index

    index < current_index ? :done : :upcoming
  end
end
