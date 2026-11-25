# The page of a creation in steps (a table: GameTableCreationHelper, a character: CharacterSheets::CreationHelper): the
# band of the steps across the whole width (shared/_steps_band), then the content (game_tables/_creation_page)
module StepsBandHelper
  # Tonal colors only: a filled plaque is kept for buttons
  STEP_MARKER_CLASSES = {
    # A thin ring in the color of the check, as on the GM badge: the tonal background alone barely showed on the band
    done: "bg-primary-soft text-primary-soft-ink ring-1 ring-inset ring-primary-soft-ink/50",
    current: "bg-primary-soft text-primary-soft-ink ring-2 ring-primary-soft-ink",
    upcoming: "border border-field-line text-muted",
    coming_soon: "border border-dashed border-field-line text-muted"
  }.freeze
  # Beyond it, the labels of the other steps show from 1280 px only (step_label_classes)
  MAX_STEPS_WITH_LABELS = 4

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
  # the marker in line with the other steps; wider on the right, where the label would touch the edge. While the
  # label is hidden (step_label_classes), the round alone: the same space on both sides (decision: the hover was
  # wider on the right of an empty place)
  def step_link_classes(step, step_count = 0)
    return "flex items-center gap-2" unless step[:path]

    side_classes = if step_count > MAX_STEPS_WITH_LABELS
                     "-mr-1.5 pr-1.5 xl:mr-0 xl:pr-3"
                   else
                     "-mr-1.5 pr-1.5 sm:mr-0 sm:pr-3"
                   end
    "-my-1.5 -ml-1.5 flex items-center gap-2 rounded-lg py-1.5 pl-1.5 #{side_classes} hover:bg-surface-raised"
  end

  # The other steps show their label from 640 px; on a band of more than four steps (the creation of a character),
  # only from 1280 px: under it, five to seven labels and their "Change" ran past the edge of the screen (at 800 px,
  # the summary was cut off). Hidden, a label stays for screen readers.
  # The current step shows its own, except on a phone in a band of more than four steps: six or seven rounds and one
  # label overflowed 375 px, widening the page (a window opened on it was off centre). The title of the page says it
  def step_label_classes(step, step_count = 0)
    long_band = step_count > MAX_STEPS_WITH_LABELS
    return "font-semibold text-ink #{'max-sm:sr-only' if long_band}".strip if step[:state] == :current

    hidden_classes = long_band ? "max-xl:sr-only" : "max-sm:sr-only"
    "#{step[:path] ? 'text-ink' : 'text-muted'} #{hidden_classes}"
  end

  # Tighter on a phone for a band of more than four steps: seven rounds hold in 343 px
  def steps_band_classes(step_count)
    step_count > MAX_STEPS_WITH_LABELS ? "flex items-center gap-1 sm:gap-3" : "flex items-center gap-1.5 sm:gap-3"
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
