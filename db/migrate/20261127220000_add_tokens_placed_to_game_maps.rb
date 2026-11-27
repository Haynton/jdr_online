class AddTokensPlacedToGameMaps < ActiveRecord::Migration[8.1]
  COUNTS_BY_CHARACTER = <<~SQL.squish.freeze
    SELECT board_tokens.game_map_id, board_tokens.character_id, MAX(board_tokens.placement) AS placed,
           COALESCE((maps.token_counters -> board_tokens.character_id::text ->> 'revealed')::int, 0) AS revealed
    FROM board_tokens JOIN game_maps AS maps ON maps.id = board_tokens.game_map_id
    GROUP BY board_tokens.game_map_id, board_tokens.character_id, maps.token_counters
  SQL

  def up
    add_column :game_maps, :tokens_placed, :integer, null: false, default: 0
    letter_tokens_across_their_map
    execute <<~SQL.squish
      UPDATE game_maps SET tokens_placed = placed.count
      FROM (SELECT game_map_id, MAX(placement) AS count FROM board_tokens GROUP BY game_map_id) AS placed
      WHERE game_maps.id = placed.game_map_id
    SQL
    keep_only_revealed_counters
  end

  def down
    letter_tokens_by_character
    count_placed_tokens_by_character
    remove_column :game_maps, :tokens_placed
  end

  private

  def letter_tokens_across_their_map
    renumber_placements("PARTITION BY game_map_id ORDER BY id")
  end

  def letter_tokens_by_character
    renumber_placements("PARTITION BY game_map_id, character_id ORDER BY id")
  end

  def renumber_placements(window)
    execute <<~SQL.squish
      UPDATE board_tokens SET placement = lettered.placement
      FROM (SELECT id, ROW_NUMBER() OVER (#{window}) AS placement FROM board_tokens) AS lettered
      WHERE board_tokens.id = lettered.id
    SQL
  end

  def count_placed_tokens_by_character
    execute <<~SQL.squish
      UPDATE game_maps SET token_counters = game_maps.token_counters || counted.counters
      FROM (
        SELECT game_map_id, jsonb_object_agg(character_id::text,
                                             jsonb_build_object('placed', placed, 'revealed', revealed)) AS counters
        FROM (#{COUNTS_BY_CHARACTER}) AS per_character
        GROUP BY game_map_id
      ) AS counted
      WHERE game_maps.id = counted.game_map_id
    SQL
  end

  def keep_only_revealed_counters
    execute <<~SQL.squish
      UPDATE game_maps SET token_counters = COALESCE(
        (SELECT jsonb_object_agg(key, value - 'placed') FROM jsonb_each(token_counters)), '{}'::jsonb)
    SQL
  end
end
