class AddNumbersToBoardTokens < ActiveRecord::Migration[8.1]
  def up
    add_column :board_tokens, :placement, :integer, null: false, default: 0
    add_column :board_tokens, :number, :integer
    add_column :game_maps, :token_counters, :jsonb, null: false, default: {}
    number_existing_tokens
    count_existing_tokens
    remove_column :board_tokens, :revealed_at
  end

  def down
    add_column :board_tokens, :revealed_at, :datetime
    execute "UPDATE board_tokens SET revealed_at = created_at WHERE number IS NOT NULL"
    remove_column :game_maps, :token_counters
    remove_column :board_tokens, :number
    remove_column :board_tokens, :placement
  end

  private

  def number_existing_tokens
    execute <<~SQL.squish
      UPDATE board_tokens SET placement = numbered.placement, number = numbered.number
      FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY game_map_id, character_id ORDER BY id) AS placement,
               CASE WHEN revealed_at IS NOT NULL THEN
                 ROW_NUMBER() OVER (PARTITION BY game_map_id, character_id, revealed_at IS NOT NULL
                                    ORDER BY revealed_at, id)
               END AS number
        FROM board_tokens
      ) AS numbered
      WHERE board_tokens.id = numbered.id
    SQL
  end

  def count_existing_tokens
    execute <<~SQL.squish
      UPDATE game_maps SET token_counters = counted.counters
      FROM (
        SELECT game_map_id,
               jsonb_object_agg(character_id::text,
                                jsonb_build_object('placed', placed, 'revealed', revealed)) AS counters
        FROM (
          SELECT game_map_id, character_id, MAX(placement) AS placed, COALESCE(MAX(number), 0) AS revealed
          FROM board_tokens GROUP BY game_map_id, character_id
        ) AS per_character
        GROUP BY game_map_id
      ) AS counted
      WHERE game_maps.id = counted.game_map_id
    SQL
  end
end
