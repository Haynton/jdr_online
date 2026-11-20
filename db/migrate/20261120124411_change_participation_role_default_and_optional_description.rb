# Everyone who joins a table is a player: only its creator is made game master, on purpose
# A table can be created before its description is written
class ChangeParticipationRoleDefaultAndOptionalDescription < ActiveRecord::Migration[8.1]
  def change
    change_column_default :participations, :role, from: "game_master", to: "player"
    change_column_null :game_tables, :description, true
  end
end
