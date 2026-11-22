# The pages of the creation of a table: the band of its steps, the buttons of the first step. The page around them
# and the look of the band: StepsBandHelper. The choices of the first step (covers, sheet templates):
# GameTableChoicesHelper
module GameTableCreationHelper
  # The id of the form of a step: its submit button points to it (form=), wherever the button sits
  CREATION_FORM_ID = "game-table-creation-form".freeze

  # A page of the creation: the band of the steps across the whole width, then the page content (steps_page)
  # game_table: the draft, once it exists, whose steps reached already open their page from the band
  def creation_page(current_step:, game_table: nil, flush_top: false, &)
    band = render("game_tables/creation_steps", current_step: current_step, game_table: game_table)
    steps_page(band: band, flush_top: flush_top, &)
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

  # The page of each step of the creation of a draft: where "Resume the creation" and "Change" lead
  def creation_step_path(game_table, step)
    case step
    when "details" then edit_game_table_details_path(game_table)
    when "summary" then game_table_summary_path(game_table)
    end
  end

  private

  def creation_step_state(step, index, current_index)
    return :coming_soon if index != current_index && GameTable::LATER_CREATION_STEPS.include?(step)

    step_state(index, current_index)
  end
end
