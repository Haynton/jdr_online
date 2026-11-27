# A non-player character or an enemy may have tokens on the maps of its table (MapLayouts::TokensCheck): deleted, its
# tokens leave them (GameMap#take_away_tokens_of), so that a map never names a character who is gone
module PlacedOnMaps
  extend ActiveSupport::Concern

  included do
    after_destroy :take_away_map_tokens, if: -> { Character::GAME_MASTER_KINDS.include?(kind) }
    after_destroy_commit :send_board_tokens_to_players, unless: :destroyed_by_association
    after_update_commit :send_new_look_to_players, if: -> { saved_change_to_name? || saved_change_to_kind? }
  end

  private

  def send_new_look_to_players
    board_map = game_table.board_game_map
    BoardTokensSender.new(game_table).call if board_map&.board_tokens&.exists?(character_id: id)
  end

  def send_board_tokens_to_players
    BoardTokensSender.new(game_table).call if game_table.board_game_map
  end

  def take_away_map_tokens
    game_table.game_maps.where.not(layout: nil).find_each { |game_map| game_map.take_away_tokens_of(self) }
  end
end
