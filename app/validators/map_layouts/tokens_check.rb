module MapLayouts
  # Checks the tokens put on a map of a table (the list "tokens" of its layout): each one { "character_id", "column",
  # "row" }, a non-player character or an enemy of the table (step "PNJ et ennemis"), on a cell of the grid, never
  # two on the same cell. The same character may have several tokens (Anthony's decision: a band of goblins) and
  # tokens on other maps. A map of « Mes cartes » has none: it belongs to no table. Gives the first error,
  # [type, options], or nil
  class TokensCheck
    TOKEN_KEYS = %w[character_id column row].freeze

    def initialize(map, tokens)
      @map = map
      @tokens = tokens
    end

    def call
      return if @tokens.empty?
      return [:tokens_without_table, {}] unless @map.respond_to?(:game_table)
      return [:invalid_token, {}] unless @tokens.all? { |token| well_formed?(token) }
      return [:unknown_token_character, {}] unless (character_ids - table_character_ids).empty?

      placement_error
    end

    private

    def placement_error
      cells = @tokens.map { |token| token.values_at("column", "row") }
      return [:token_outside_grid, {}] unless cells.all? { |column, row| column < @map.columns && row < @map.rows }

      [:tokens_overlap, {}] unless cells.uniq.size == cells.size
    end

    def well_formed?(token)
      token.is_a?(Hash) && token.keys.sort == TOKEN_KEYS.sort &&
        token.values.all? { |value| value.is_a?(Integer) && value >= 0 }
    end

    def character_ids
      @tokens.map { |token| token["character_id"] }.uniq
    end

    def table_character_ids
      @map.game_table ? @map.game_table.npcs.ids : []
    end
  end
end
