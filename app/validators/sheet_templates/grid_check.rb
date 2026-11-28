module SheetTemplates
  # The length of a cell of the maps (character_fields.grid: cell_length, unit), when the template says it: a positive
  # number and the short name of its unit in the words of the game (« m », « ft »). The board counts its moves in cells
  # and shows them in this distance (decision of 27 November); a map may later give its own
  class GridCheck < Check
    UNIT_MAX_LENGTH = 10

    def call
      grid = @sheet_template.character_fields.to_h["grid"]
      return [] if grid.nil? || valid?(grid)

      [[:invalid_grid, { count: UNIT_MAX_LENGTH }]]
    end

    private

    def valid?(grid)
      grid.is_a?(Hash) && grid.keys.sort == %w[cell_length unit] && positive_number?(grid["cell_length"]) &&
        short_name?(grid["unit"])
    end

    def positive_number?(value)
      value.is_a?(Numeric) && value.positive?
    end

    def short_name?(value)
      value.is_a?(String) && value.strip.length.between?(1, UNIT_MAX_LENGTH)
    end
  end
end
