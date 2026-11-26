module MapLayouts
  # Checks the tokens put on a map of a table (the list "tokens" of its layout): each one { "character_id", "column",
  # "row" }, and "hidden" (true or false, hidden when it is not said), a non-player character or an enemy of the table
  # (step "PNJ et ennemis", or copied from the bestiary in the editor), on a cell of the grid, never two on the same
  # cell, never on a blocked zone painted by the game master (the empty ground is refused by the editor only: a map
  # switched from its picture to its drawing could otherwise never be saved again). The same character may have
  # several tokens (Anthony's decision: a band of goblins) and tokens on other maps. A map of « Mes cartes » has none:
  # it belongs to no table. Gives the first error, [type, options], or nil
  class TokensCheck
    TOKEN_KEYS = %w[character_id column row].freeze
    OPTIONAL_TOKEN_KEYS = %w[hidden].freeze

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
      return [:tokens_overlap, {}] unless cells.uniq.size == cells.size

      [:token_on_blocked_cell, {}] if cells.map { |column, row| "#{column},#{row}" }.intersect?(painted_cells)
    end

    def painted_cells
      Array(@map.layout["blocked"])
    end

    def well_formed?(token)
      return false unless token.is_a?(Hash) && (TOKEN_KEYS - token.keys).empty?
      return false unless (token.keys - TOKEN_KEYS - OPTIONAL_TOKEN_KEYS).empty?

      token.values_at(*TOKEN_KEYS).all? { |value| value.is_a?(Integer) && value >= 0 } && hidden_or_shown?(token)
    end

    def hidden_or_shown?(token)
      !token.key?("hidden") || [true, false].include?(token["hidden"])
    end

    def character_ids
      @tokens.map { |token| token["character_id"] }.uniq
    end

    def table_character_ids
      @map.game_table ? @map.game_table.npcs.ids : []
    end
  end
end
