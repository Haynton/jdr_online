# The panel « Dés » of the game room (game_rooms/panels/_dice): the dice the roller knows (DiceRoller), the modes the
# template declares (TemplateCopy#dice_rolls) and the last roll of who is reading
module GameRoomDiceHelper
  DEFAULT_SIDES = 20
  # One die among the seven, a real radio inside its label (the whole pill clickable, without JavaScript too); the one
  # chosen in gold tonal, framed in brass, like a chosen card
  DIE_CLASSES = %w[
    flex h-10 cursor-pointer items-center justify-center rounded-lg border border-line text-sm font-semibold
    text-ink tabular-nums transition-colors hover:bg-surface-raised has-checked:border-brass has-checked:bg-primary-soft
    has-checked:text-primary-soft-ink has-focus-visible:outline-2 has-focus-visible:outline-offset-2
    has-focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The modes drawn like the theme selector (an option always chosen), greyed out where they do not apply (a mode
  # rolls a single die of its sides, dice_panel_controller.js)
  MODE_OPTION_CLASSES = %w[
    inline-flex h-8 min-w-0 flex-1 cursor-pointer items-center justify-center rounded-md px-2 text-sm text-ink
    transition-colors hover:bg-surface/60 has-checked:bg-surface has-checked:font-semibold has-checked:shadow-sm
    has-disabled:cursor-not-allowed has-disabled:opacity-50 has-disabled:hover:bg-transparent
    has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring
  ].join(" ").freeze
  RESULT_ID = "dice-roll-result".freeze

  def dice_modes(game_table)
    Array(game_table.dice_rolls["modes"])
  end

  def dice_panel_data(game_table)
    { controller: "dice-panel", dice_panel_modes_on_sides_value: game_table.dice_rolls["modes_on_sides"].to_i,
      action: "change->dice-panel#updateModes input->dice-panel#updateModes" }
  end

  def dice_number_input(form, attribute, range, value:)
    form.number_field(attribute, value: value, min: range.min, max: range.max, required: true,
                                 id: "dice-roll-#{attribute}", class: CharacterSheets::FieldsHelper::STEPPER_INPUT_CLASSES,
                                 data: { number_stepper_target: "input", dice_panel_target: attribute.to_s })
  end

  # « 7, 15 » for the dice of the roll shown in the panel
  def dice_result_dice(line)
    Array(line.event_params["dice"]).join(", ")
  end
end
