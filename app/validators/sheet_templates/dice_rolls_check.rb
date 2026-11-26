module SheetTemplates
  # The dice of the game room (character_fields.dice_rolls), when the template declares them: its modes (advantage,
  # disadvantage: `dice` dice rolled for one, keeping the highest or the lowest), on which die they apply
  # (modes_on_sides), and its roll of initiative (a die, plus the value of a field of the sheet of a character and of
  # an NPC). The dice are those the roller knows (DiceRoller::SIDES)
  class DiceRollsCheck < Check
    PARAMETERS = %w[modes modes_on_sides initiative].freeze
    MODE_PARAMETERS = %w[key label help dice keep].freeze
    INITIATIVE_PARAMETERS = %w[label sides modifier_from npc_modifier_from].freeze
    MODE_DICE = (2..5)
    HELP_MAX_LENGTH = 200
    # A field gives a number to add when it is a number, a calculated value or an ability (its modifier)
    NUMBER_TYPES = %w[number computed ability].freeze

    def call
      dice_rolls = @sheet_template.character_fields.to_h["dice_rolls"]
      return [] if dice_rolls.nil?
      return [[:invalid_dice_rolls, {}]] unless dice_rolls.is_a?(Hash)

      unknown_errors(dice_rolls.keys - PARAMETERS, :unknown_dice_rolls_parameter) +
        modes_errors(dice_rolls) + initiative_errors(dice_rolls["initiative"])
    end

    private

    def unknown_errors(parameters, error_type, **place)
      parameters.map { |parameter| [error_type, place.merge(parameter: parameter)] }
    end

    def modes_errors(dice_rolls)
      modes = dice_rolls["modes"]
      return [] if modes.nil?
      return [[:invalid_dice_roll_modes, {}]] unless modes.is_a?(Array) && modes.all?(Hash)

      modes.flat_map { |mode| mode_errors(mode) } + duplicate_mode_errors(modes) +
        sides_errors(dice_rolls["modes_on_sides"], :invalid_modes_on_sides)
    end

    def mode_errors(mode)
      key = mode["key"].to_s
      errors = unknown_errors(mode.keys - MODE_PARAMETERS, :unknown_dice_roll_mode_parameter, mode: key)
      errors << [:invalid_dice_roll_mode_key, { key: key }] unless valid_key?(mode["key"])
      errors + mode_label_errors(mode, key) + mode_help_errors(mode, key) + mode_dice_errors(mode, key)
    end

    def mode_label_errors(mode, key)
      return [] if valid_label?(mode["label"])

      [[:invalid_dice_roll_mode_label, { mode: key, count: LABEL_MAX_LENGTH }]]
    end

    def mode_help_errors(mode, key)
      return [] if valid_help?(mode["help"])

      [[:invalid_dice_roll_mode_help, { mode: key, count: HELP_MAX_LENGTH }]]
    end

    def mode_dice_errors(mode, key)
      dice = mode["dice"]
      return [] if dice.is_a?(Integer) && MODE_DICE.cover?(dice) && DiceRoller::KEPT_DIE.key?(mode["keep"])

      [[:invalid_dice_roll_mode, { mode: key, min: MODE_DICE.min, max: MODE_DICE.max }]]
    end

    def duplicate_mode_errors(modes)
      keys = modes.pluck("key").compact
      keys.select { |key| keys.count(key) > 1 }.uniq.map { |key| [:duplicate_dice_roll_mode, { key: key }] }
    end

    def sides_errors(sides, error_type)
      return [] if DiceRoller::SIDES.include?(sides)

      [[error_type, { sides: DiceRoller::SIDES.map { |side| "d#{side}" }.to_sentence }]]
    end

    def initiative_errors(initiative)
      return [] if initiative.nil?
      return [[:invalid_initiative_roll, {}]] unless initiative.is_a?(Hash)

      errors = unknown_errors(initiative.keys - INITIATIVE_PARAMETERS, :unknown_initiative_parameter)
      errors << [:invalid_initiative_label, { count: LABEL_MAX_LENGTH }] unless valid_label?(initiative["label"])
      errors + sides_errors(initiative["sides"], :invalid_initiative_sides) +
        modifier_field_errors(initiative["modifier_from"], "character_fields") +
        modifier_field_errors(initiative["npc_modifier_from"], "npc_fields")
    end

    # Each one is optional: without it, nothing is added to the die
    def modifier_field_errors(key, part)
      return [] if key.nil?
      return [] if fields_of(part).any? { |field| field["key"] == key && NUMBER_TYPES.include?(field["type"]) }

      [[:invalid_initiative_field, context(part).merge(key: key.to_s)]]
    end

    def valid_help?(help)
      help.nil? || (help.is_a?(String) && help.length <= HELP_MAX_LENGTH && !help.match?(CONTROL_CHARACTERS))
    end
  end
end
