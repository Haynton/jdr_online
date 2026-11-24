module MapLayouts
  # Checks the objects of a drawing (the list "objects" of its layout): each one { "key", "column", "row", "rotation" },
  # an object of MapObjects, turned by quarter turns (0 to 3), its cells (from column and row, its size once turned)
  # inside the grid and on floor cells, never on the cells of another object. Gives the first error, [type, options],
  # or nil: a broken drawing could hold dozens. (« object » is a reserved word of the messages of errors: object_name)
  class ObjectsCheck
    OBJECT_KEYS = %w[key column row rotation].freeze
    ROTATIONS = (0..3)

    def initialize(map, objects)
      @map = map
      @objects = objects
      @taken_cells = Set.new
    end

    def call
      @objects.each do |placed_object|
        error = error_for(placed_object)
        return error if error
      end
      nil
    end

    private

    def error_for(placed_object)
      return [:invalid_object, {}] unless well_formed?(placed_object)

      map_object = MapObjects.find(placed_object["key"])
      return [:unknown_object, { object_name: placed_object["key"] }] unless map_object

      placement_error(map_object, cells_of(placed_object, map_object))
    end

    # The object named in the words of the page (« Lit »)
    def placement_error(map_object, cells)
      named = { object_name: I18n.t("map_templates.objects.#{map_object.key}") }
      return [:object_outside_grid, named] unless cells.all? { |cell| inside?(cell) }
      return [:object_off_floor, named] unless cells.all? { |cell| floor_at?(cell) }
      return [:objects_overlap, named] if cells.any? { |cell| @taken_cells.include?(cell) }

      @taken_cells.merge(cells)
      nil
    end

    def well_formed?(placed_object)
      placed_object.is_a?(Hash) && placed_object.keys.sort == OBJECT_KEYS.sort &&
        %w[column row].all? { |position| placed_object[position].is_a?(Integer) } &&
        ROTATIONS.include?(placed_object["rotation"])
    end

    # Turned a quarter or three quarters, an object of 2 × 1 takes 1 × 2 cells
    def cells_of(placed_object, map_object)
      size = [map_object.width, map_object.height]
      columns, rows = placed_object["rotation"].odd? ? size.reverse : size
      columns.times.flat_map do |column_offset|
        rows.times.map { |row_offset| [placed_object["column"] + column_offset, placed_object["row"] + row_offset] }
      end
    end

    def inside?((column, row))
      column >= 0 && row >= 0 && column < @map.columns.to_i && row < @map.rows.to_i
    end

    def floor_at?((column, row))
      @map.layout["floors"].key?("#{column},#{row}")
    end
  end
end
