# A non-player character or an enemy may have tokens on the maps of its table (MapLayouts::TokensCheck): deleted, its
# tokens leave them (GameMap#take_away_tokens_of), so that a map never names a character who is gone
module PlacedOnMaps
  extend ActiveSupport::Concern

  included do
    after_destroy :take_away_map_tokens, if: -> { Character::GAME_MASTER_KINDS.include?(kind) }
  end

  private

  def take_away_map_tokens
    game_table.game_maps.where.not(layout: nil).find_each { |game_map| game_map.take_away_tokens_of(self) }
  end
end
