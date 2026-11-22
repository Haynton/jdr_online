# The pages of the creation of a character in steps (GameTables::CharacterStepsController): the band of its steps,
# the buttons, the summary. The page around them and the look of the band: StepsBandHelper
module CharacterCreationHelper
  # A step of the creation: the band of the steps of this character, then the page content (steps_page)
  def character_creation_page(character:, current_step:, &)
    band = render("shared/steps_band", steps: character_band_steps(character, current_step),
                                       label: t("game_tables.character_steps.band_label"))
    steps_page(band: band, &)
  end

  # Each step with its number, its state for the step being filled in, and its page once reached
  def character_band_steps(character, current_step)
    steps = character.creation_steps.all
    current_index = steps.index(current_step)
    steps.each_with_index.map do |step, index|
      { key: step.key, number: index + 1, label: character_step_label(step), state: step_state(index, current_index),
        path: (character_step_link(character, step) if index != current_index) }
    end
  end

  # The name given by the template; the summary, and the single step of a template without steps, are named by the app
  def character_step_label(step)
    step.label || t("game_tables.character_steps.steps.#{step.key}")
  end

  # The step before, for "Back" (none on the first one)
  def previous_character_step_path(character, step)
    previous_step = character.creation_steps.before(step)
    game_table_character_step_path(character.game_table, previous_step.key) if previous_step
  end

  # What the live calculation reads beside the fields of the page: the values of the other steps, the effects of the
  # lists, and what the server worked out (modifiers, bonuses), for the fields that are not on this page
  def character_sheet_form_data(character, computed)
    { controller: "character-sheet",
      action: "input->character-sheet#recompute change->character-sheet#recompute",
      character_sheet_level_thresholds_value: character.game_table.level_thresholds.to_json,
      character_sheet_sheet_value: character.sheet.to_json,
      character_sheet_effects_value: choice_effects(character.sheet_fields).to_json,
      character_sheet_calculated_value: computed.to_json }
  end

  # The lines of the summary for one step: the label of each field filled in and its value, as written on a sheet
  # A computed value (hit points, armour class) is read from what the server worked out
  def character_summary_rows(character, step, computed)
    step.fields.filter_map do |field|
      text = if field["type"] == "computed"
               computed[:values][field["key"]]&.then { |value| format_computed_value(value) }
             else
               character_summary_value(field, character.sheet[field["key"]])
             end
      [field["label"], text] if text.present?
    end
  end

  private

  def character_step_link(character, step)
    return unless character.persisted? && character.creation_step_reached?(step)

    game_table_character_step_path(character.game_table, step.key)
  end

  def choice_effects(fields)
    fields.select { |field| field["effects"] }.to_h { |field| [field["key"], field["effects"]] }
  end

  # A bonus shows only when its proficiency is ticked; a yes-or-no value as yes or no; a resource by its maximum
  def character_summary_value(field, value)
    case field["type"]
    when "bonus" then t("game_tables.character_steps.summary.proficient") if value == true
    when "boolean" then t(value ? "answer_yes" : "answer_no", scope: "game_tables.character_steps.summary")
    when "resource" then value.is_a?(Hash) ? number_with_delimiter(value["max"]) : nil
    when "number", "ability", "experience" then value.nil? ? nil : number_with_delimiter(value)
    else value
    end
  end
end
