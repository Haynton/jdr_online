# The level of a player's character in the game (decision of 26 November): the game master gives the next one
# (level_up_to), the player then makes its choices (LevelUp). One level at a time, up to the last, and only with a
# template whose table gives the level (a field from_table: starting_level)
module CharacterLevels
  extend ActiveSupport::Concern

  MAXIMUM_LEVEL = 20

  # The level it plays at: the one in its sheet, or the starting level of its table
  def current_level
    spell_choices.level
  end

  def levels_up?
    sheet_fields.any? { |field| field["from_table"] == "starting_level" }
  end

  # The level given, nil when a level waits already, at the last level, or without levels
  def grant_level
    return if level_up_to || !levels_up? || current_level >= MAXIMUM_LEVEL

    self.level_up_to = current_level + 1
  end
end
