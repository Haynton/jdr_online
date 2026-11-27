# The scores typed by hand with a roll become a choice of the game master (decision of 27 November): a new table keeps
# the roll made here. The tables already created keep what they have
class TurnAbilityScoresTypedOffByDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :game_tables, :ability_scores_typed, from: true, to: false
  end
end
