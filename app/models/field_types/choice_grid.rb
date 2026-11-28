module FieldTypes
  # The grid of a list (FieldTypes::Choice): its options as the cells of a table of two axes, picked by one choice on
  # each axis (the alignment: its order, then its morals), each with its meaning. A grid names its two axes and their
  # values, holds a row of options per value of the rows and a cell per value of the columns, every option of the list
  # once, and means options of the list
  module ChoiceGrid
    module_function

    def errors(field)
      grid = field["grid"]
      return [] unless grid
      return [[:invalid_grid, {}]] unless well_formed?(grid)

      unknown_errors(grid, field["options"].to_a) + placement_errors(grid, field["options"].to_a)
    end

    def unknown_errors(grid, options)
      unknown = (grid["options"].flatten - options) + (grid["meanings"].to_h.keys - options)
      unknown.uniq.map { |option| [:unknown_option, { setting: "grid", option: option.to_s }] }
    end

    def placement_errors(grid, options)
      cells = grid["options"].flatten
      cells.tally.values.all?(1) && (options - cells).empty? ? [] : [[:invalid_grid, {}]]
    end

    def well_formed?(grid)
      return false unless grid.is_a?(Hash) && %w[columns rows].all? { |axis| axis?(grid[axis]) }
      return false unless grid["meanings"].nil? || grid["meanings"].is_a?(Hash)

      rows?(grid["options"], grid.dig("rows", "values").size, grid.dig("columns", "values").size)
    end

    def rows?(rows, row_count, column_count)
      rows.is_a?(Array) && rows.size == row_count && rows.all? { |row| row.is_a?(Array) && row.size == column_count }
    end

    def axis?(axis)
      axis.is_a?(Hash) && axis["label"].is_a?(String) && axis["values"].is_a?(Array) && axis["values"].size > 1
    end
  end
end
