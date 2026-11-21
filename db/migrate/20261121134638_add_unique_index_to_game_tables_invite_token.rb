# Every table gets its invitation token (the secret part of its invitation link), unique to it.
# The tables made before get one here, in SQL: a migration does not rely on the models, which change over time.
# From now on, has_secure_token gives one to each new table (GameTable)
class AddUniqueIndexToGameTablesInviteToken < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE game_tables SET invite_token = replace(gen_random_uuid()::text, '-', '') WHERE invite_token IS NULL
    SQL
    add_index :game_tables, :invite_token, unique: true
  end

  def down
    remove_index :game_tables, :invite_token
  end
end
