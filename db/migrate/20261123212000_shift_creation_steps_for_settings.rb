# The step Settings is now the second one of the creation of a table (GameTable::CREATION_STEPS): creation_step holds
# the number of the step reached, so every table that went past the first step moves up by one, and keeps resuming
# where it was (a draft at its summary stays at its summary)
class ShiftCreationStepsForSettings < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE game_tables SET creation_step = creation_step + 1 WHERE creation_step >= 2"
  end

  def down
    execute "UPDATE game_tables SET creation_step = creation_step - 1 WHERE creation_step >= 3"
  end
end
