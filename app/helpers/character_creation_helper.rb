# The pages of the creation of a character in steps (GameTables::CharacterStepsController): the band of its steps,
# the buttons, the summary. The page around them and the look of the band: StepsBandHelper
module CharacterCreationHelper
  # A step of the creation: the band of the steps of this character, then the page content (steps_page)
  def character_creation_page(character:, current_step:, &)
    band = render("shared/steps_band", steps: character_band_steps(character, current_step),
                                       label: t("game_tables.character_steps.band_label"))
    steps_page(band: band, &)
  end

  # Each step with its number, its state for the step being filled in, and its page once reached. On a step with a
  # form, following a step of the band saves the form first (saves_form, save_before_leaving_controller.js)
  def character_band_steps(character, current_step)
    steps = character.creation_steps.all
    current_index = steps.index(current_step)
    steps.each_with_index.map do |step, index|
      path = (character_step_link(character, step) if index != current_index)
      { key: step.key, number: index + 1, label: character_step_label(step), state: step_state(index, current_index),
        path: path, saves_form: path.present? && !current_step.summary? }
    end
  end

  # The name given by the template; the summary, and the single step of a template without steps, are named by the app
  def character_step_label(step)
    step.label || t("game_tables.character_steps.steps.#{step.key}")
  end

  # What the live calculation reads beside the fields of the page: the values of the other steps, the effects of the
  # lists, and what the server worked out (modifiers, bonuses), for the fields that are not on this page
  # save-before-leaving: a step of the band sends the form first (save_before_leaving_controller.js)
  def character_sheet_form_data(character, computed)
    { controller: "character-sheet save-before-leaving",
      action: "input->character-sheet#recompute change->character-sheet#recompute " \
              "formdata->character-sheet#sendTypedScores",
      character_sheet_level_thresholds_value: character.game_table.level_thresholds.to_json,
      character_sheet_sheet_value: character.sheet.to_json,
      character_sheet_effects_value: choice_effects(character.sheet_fields).to_json,
      character_sheet_calculated_value: computed.to_json }
  end

  private

  def character_step_link(character, step)
    return unless character.persisted? && character.creation_step_reached?(step)

    game_table_character_step_path(character.game_table, step.key)
  end

  def choice_effects(fields)
    fields.select { |field| field["effects"] }.to_h { |field| [field["key"], field["effects"]] }
  end
end
