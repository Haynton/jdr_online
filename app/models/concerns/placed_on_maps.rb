# A character may have tokens on the maps of its table (MapLayouts::TokensCheck): deleted, its tokens leave them
# (GameMap#take_away_tokens_of), so that a map never names a character who is gone. A player character goes with its
# participation (a player removed from the table): the players see its token leave; not when the whole table goes
module PlacedOnMaps
  extend ActiveSupport::Concern

  included do
    scope :placeable_on_the_board, -> { of_game_master.or(pc.complete) }

    after_destroy :take_away_map_tokens
    after_destroy_commit :send_board_tokens_to_players, unless: :destroyed_with_its_table?
    after_update_commit :send_new_look_to_players, if: -> { saved_change_to_name? || saved_change_to_kind? }
  end

  def placeable_on_the_board?
    kind.in?(Character::GAME_MASTER_KINDS) || (pc? && complete?)
  end

  private

  def send_new_look_to_players
    board_map = game_table.board_game_map
    BoardTokensSender.new(game_table).call([self]) if board_map&.board_tokens&.exists?(character_id: id)
  end

  def destroyed_with_its_table?
    destroyed_by_association&.active_record == GameTable
  end

  def send_board_tokens_to_players
    BoardTokensSender.new(game_table).call if game_table.board_game_map
  end

  def take_away_map_tokens
    game_table.game_maps.where.not(layout: nil).find_each { |game_map| game_map.take_away_tokens_of(self) }
  end
end
