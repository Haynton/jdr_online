class CreateParticipations < ActiveRecord::Migration[8.0]
  def change
    create_table :participations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game_table, null: false, foreign_key: true
      t.string :role, null: false, default: "game_master"
      t.timestamps
    end
    add_index :participations,
              [:user_id, :game_table_id],
              unique: true,
              name: "index_participations_on_user_and_game_table"
    add_index :participations,
              :game_table_id,
              unique: true,
              where: "role = 'game_master'",
              name: "index_participations_one_game_master_per_table"
    add_check_constraint :participations,
                         "role IN ('game_master', 'player')",
                         name: "participations_role_check"
  end
end
