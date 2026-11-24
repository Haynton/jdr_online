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

  # Cancel then Continue, at the end of the form of the first step on the right: Continue sends the form by its id.
  # saving: Save instead of Continue, on a table ready (its "Game settings"): the step is saved and shown again
  def creation_actions(cancel_path:, saving: false)
    cancel_link = link_to(t("game_tables.creation_actions.cancel"), cancel_path, class: button_classes(:secondary))
    submit_label = saving ? t("game_tables.creation_actions.save") : t("game_tables.creation_actions.continue")
    submit_button = button_tag(submit_label, type: :submit, form: CREATION_FORM_ID, class: button_classes(:primary))
    cancel_link + submit_button
  end

  # A line of the list of settings (step Settings): its name and help on the left, its control on the right, under
  # them on a phone. 72 px high at least, so that a line with a short help keeps the height of the others
  SETTING_LINE_CLASSES = %w[
    flex min-h-18 flex-col gap-3 py-4 sm:flex-row sm:items-center sm:justify-between sm:gap-8
  ].join(" ").freeze

  def setting_line_classes
    SETTING_LINE_CLASSES
  end

  # The title of a group of settings (gold small capitals, like the sections of the template editor), then its lines
  def settings_group_title_classes
    "text-xs font-semibold tracking-wider text-brass uppercase"
  end

  def settings_group_lines_classes
    "mt-3 divide-y divide-line border-y border-line"
  end

  # The functions of the AI, announced on the step Settings but not working yet: their switches will be stored in
  # game_tables.ai_settings under these keys
  AI_SETTINGS = %w[session_summary campaign_memory natural_language_sheet action_command].freeze

  def ai_settings
    AI_SETTINGS
  end

  # Rules of the game announced on the step Settings, not working yet, with their ways to play them (in their texts):
  # the ones of the creation of a character, then the ones of the game. The encumbrance, a yes or no, follows them
  CHARACTER_RULES_COMING_SOON = %w[later_hit_points starting_equipment].freeze
  GAME_RULES_COMING_SOON = %w[progression rest].freeze

  def character_rules_coming_soon
    CHARACTER_RULES_COMING_SOON
  end

  def game_rules_coming_soon
    GAME_RULES_COMING_SOON
  end

  # The ways the template offers to get the scores of the abilities, by their label, then the player's choice
  def ability_method_options(game_table)
    game_table.ability_methods.map { |method| [method["label"], method["type"]] } +
      [[t("game_tables.settings.edit.player_choice"), TableRules::PLAYER_CHOICE]]
  end

  # A list of the look of the fields, disabled, its chevron drawn beside it (CollectionSelectInput)
  def coming_soon_choice_classes
    "#{SimpleFormFieldClasses::INPUT} #{CollectionSelectInput::SELECT_CLASSES}"
  end

  # The number field of the starting level (step Settings), between "−" and "+" (character_sheets/fields/_stepper),
  # with the look of the numbers of a character sheet. Red with its message under it when refused
  def starting_level_input(form)
    form.number_field :starting_level, min: GameTable::STARTING_LEVELS.min, max: GameTable::STARTING_LEVELS.max,
                                       class: CharacterSheets::FieldsHelper::STEPPER_INPUT_CLASSES,
                                       aria: starting_level_aria(form.object), data: { number_stepper_target: "input" }
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
    when "settings" then edit_game_table_settings_path(game_table)
    when "catalog" then edit_game_table_catalog_path(game_table)
    when "npcs" then edit_game_table_cast_path(game_table)
    when "summary" then game_table_summary_path(game_table)
    end
  end

  private

  def starting_level_aria(game_table)
    return { describedby: "starting-level-hint" } unless game_table.errors.include?(:starting_level)

    { invalid: true, describedby: "starting-level-error starting-level-hint" }
  end

  def creation_step_state(step, index, current_index)
    return :coming_soon if index != current_index && GameTable::LATER_CREATION_STEPS.include?(step)

    step_state(index, current_index)
  end
end
