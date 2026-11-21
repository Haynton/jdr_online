# The pages of the creation of a table: the band of the steps, the page around them, the buttons of the first step.
# The choices of the first step (covers, sheet templates): GameTableChoicesHelper
module GameTableCreationHelper
  # Tonal colors only: a filled plaque is kept for buttons
  STEP_MARKER_CLASSES = {
    done: "bg-primary-soft text-primary-soft-ink",
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
  def creation_page(current_step:, flush_top: false, &)
    content = capture(&)
    content_for(:full_width_page) do
      render "game_tables/creation_page", current_step: current_step, flush_top: flush_top, content: content
    end
  end

  def creation_main_classes(flush_top)
    flush_top ? "px-4 pb-12 sm:px-8" : "px-4 pt-8 pb-12 sm:px-8"
  end

  # A message shown on screen, pulled up by its own top margin (mt-4) under the usual space, kept apart from what
  # follows. No space at all without one: the screen reader message takes no room
  def creation_messages_classes(flush_top)
    return "" unless visible_messages?

    flush_top ? "mb-4" : "-mt-4 mb-6"
  end

  # The messages of shared/_flashes that show on screen (flash[:screen_reader_notice] does not)
  def visible_messages?
    flash[:notice].present? || flash[:alert].present?
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

  # Each step of the creation, with its number and its state for the step being filled in
  def creation_steps(current_step)
    current_index = GameTable::CREATION_STEPS.index(current_step)
    GameTable::CREATION_STEPS.each_with_index.map do |step, index|
      { key: step, number: index + 1, state: creation_step_state(step, index, current_index) }
    end
  end

  def step_marker_classes(state)
    STEP_MARKER_CLASSES.fetch(state)
  end

  # On a phone, only the label of the current step shows: the labels of all the steps do not fit side by side
  def step_label_classes(state)
    state == :current ? "font-semibold text-ink" : "text-muted max-sm:sr-only"
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
