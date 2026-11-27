# The roll of the abilities kept on a character being made (ability_rolls, rolled by the server): one roll, then one
# roll again when the table allows it (GameTable#ability_rerolls; decision: only one, the second roll is kept)
module CharacterAbilityRolls
  extend ActiveSupport::Concern

  def may_roll_abilities?
    return true if ability_rolls.blank?

    game_table.ability_rerolls && !ability_rerolled
  end
end
