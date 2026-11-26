module DiceRolls
  # What the recorders of the rolls share: the mode asked from the panel (advantage), only one the template declares
  # (TemplateCopy#dice_rolls) and only on the die it applies to; and the notation of the roll, with the label of its
  # mode, written by the template in the words of the game: « 1d20+5 (Avantage) »
  module Modes
    private

    def declared_mode(game_table, mode_key, sides)
      return if mode_key.blank?

      dice_rolls = game_table.dice_rolls
      mode = Array(dice_rolls["modes"]).find { |candidate| candidate["key"] == mode_key }
      raise Roller::InvalidRoll, "unknown mode: #{mode_key}" unless mode
      raise Roller::InvalidRoll, "no mode on a d#{sides}" unless dice_rolls["modes_on_sides"] == sides

      mode
    end

    def notation(result, mode)
      mode ? "#{result.notation} (#{mode['label']})" : result.notation
    end
  end
end
