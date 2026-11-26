module DiceRolls
  # What the recorders of the rolls share: the mode asked from the panel (advantage), only one the template declares
  # (TemplateCopy#dice_rolls), on any die (decision of 26 November); and the notation of the roll, with the label of its
  # mode, written by the template in the words of the game: « 1d20+5 (Avantage) »
  module Modes
    private

    def declared_mode(game_table, mode_key)
      return if mode_key.blank?

      mode = Array(game_table.dice_rolls["modes"]).find { |candidate| candidate["key"] == mode_key }
      raise Roller::InvalidRoll, "unknown mode: #{mode_key}" unless mode

      mode
    end

    def notation(result, mode)
      mode ? "#{result.notation} (#{mode['label']})" : result.notation
    end
  end
end
