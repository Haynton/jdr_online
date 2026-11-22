# The pages of the creation of a table: the band of the steps, the page around them, the buttons of the first step.
# The choices of the first step (covers, sheet templates): GameTableChoicesHelper
module GameTableCreationHelper
  # Tonal colors only: a filled plaque is kept for buttons
  STEP_MARKER_CLASSES = {
    # A thin ring in the color of the check, as on the GM badge: the tonal background alone barely showed on the band
    done: "bg-primary-soft text-primary-soft-ink ring-1 ring-inset ring-primary-soft-ink/50",
    current: "bg-primary-soft text-primary-soft-ink ring-2 ring-primary-soft-ink",
    upcoming: "border border-field-line text-muted",
    coming_soon: "border border-dashed border-field-line text-muted"
  }.freeze

  # The id of the form of a step: its submit button points to it (form=), wherever the button sits
  CREATION_FORM_ID = "game-table-creation-form".freeze

  # A page of the creation: the band of the steps across the whole width, then the page content.
  # The block is captured here, while the page is still the current template, so that its short translation
  # keys (t(".title")) are looked up for the page and not for the partial (same as auth_card)
  # flush_top: no space above the content, which touches the band of the steps (a cover from edge to edge)
  # game_table: the draft, once it exists, whose steps reached already open their page from the band
  def creation_page(current_step:, game_table: nil, flush_top: false, &)
    content = capture(&)
    content_for(:full_width_page) do
      render "game_tables/creation_page", current_step: current_step, game_table: game_table,
                                          flush_top: flush_top, content: content
    end
  end

  def creation_main_classes(flush_top)
    flush_top ? "px-4 pb-12 sm:px-8" : "px-4 pt-8 pb-12 sm:px-8"
  end

  def creation_form_id
    CREATION_FORM_ID
  end

  # Cancel then Continue, at the end of the form of the first step on the right: Continue sends the form by its id
  def creation_actions(cancel_path:)
    cancel_link = link_to(t("game_tables.creation_actions.cancel"), cancel_path, class: button_classes(:secondary))
    continue_button = button_tag(t("game_tables.creation_actions.continue"),
                                 type: :submit, form: CREATION_FORM_ID, class: button_classes(:primary))
    cancel_link + continue_button
  end

  # Each step of the creation, with its number, its state for the step being filled in, and its page when the
  # game master may go back to it
  def creation_steps(current_step, game_table = nil)
    current_index = GameTable::CREATION_STEPS.index(current_step)
    GameTable::CREATION_STEPS.each_with_index.map do |step, index|
      { key: step, number: index + 1, state: creation_step_state(step, index, current_index),
        path: (creation_step_path(game_table, step) if step_open_from_band?(game_table, index, current_index)) }
    end
  end

  # A step reached already opens its page: its form was accepted (a step never reached stays closed)
  def step_open_from_band?(game_table, index, current_index)
    return false if game_table.nil? || index == current_index

    index < game_table.creation_step.to_i
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
    return t("game_tables.creation_steps.coming_soon") if step[:state] == :coming_soon
    return unless step[:path]

    t(step[:state] == :done ? "game_tables.creation_steps.change" : "game_tables.creation_steps.open")
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

  # The page of each step of the creation of a draft: where "Resume the creation" and "Change" lead
  def creation_step_path(game_table, step)
    case step
    when "details" then edit_game_table_details_path(game_table)
    when "summary" then game_table_summary_path(game_table)
    end
  end

  private

  def creation_step_state(step, index, current_index)
    return :current if index == current_index
    return :coming_soon if GameTable::LATER_CREATION_STEPS.include?(step)

    index < current_index ? :done : :upcoming
  end
end
