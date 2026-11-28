# What stops a token on a drawn map of a table, for the board (Anthony's decisions: the map editor does not restrain
# the game master; breaking a wall or swimming is decided by the game master during the game). Read from the layout
# of the map, ready to use:
#
#   blocked_cells: [[column, row], ...]   # a cell no token stands on: the empty ground (a drawn map), and the cells
#                                         # painted by the game master with the brush « Zones bloquantes »
#   blocked_sides: ["3,4|4,4", ...]       # a side no token crosses, two cells written like the edges of the layout:
#                                         # the walls a room or stones draw by themselves (MapFloors#walls_block?)
#
# The walls, low walls and doors put by hand, the water, the objects are all crossed. A door put in the wall of a
# floor is its way in. On a map played on a picture, only the cells painted are blocked. Cells counted from 0.
# Its moves step by step: MapPassage::Steps
class MapPassage
  DOOR = "door".freeze
  # The four neighbours of a cell
  NEIGHBOUR_OFFSETS = [[1, 0], [-1, 0], [0, 1], [0, -1]].freeze

  include Steps

  def initialize(map)
    @layout = map.layout.to_h
    @columns = map.columns.to_i
    @rows = map.rows.to_i
  end

  def blocked_cells
    painted = Array(@layout["blocked"]).map { |cell_key| cell_position(cell_key) }
    return painted.sort if on_picture?

    (empty_cells + painted).uniq.sort
  end

  def blocked_sides
    return [] if on_picture?

    floors.flat_map { |cell_key, floor| blocked_sides_of(cell_position(cell_key), floor) }.uniq.sort
  end

  private

  def on_picture?
    @layout["mode"] == "picture"
  end

  # The floors known to the registry, by cell
  def floors
    @floors ||= @layout["floors"].to_h.filter_map do |cell_key, floor_key|
      floor = MapFloors.find(floor_key)
      [cell_key, floor] if floor
    end.to_h
  end

  def empty_cells
    (0...@columns).to_a.product((0...@rows).to_a).reject { |column, row| floors.key?("#{column},#{row}") }
  end

  # Only towards another floor: a token never stands on the empty ground, so the side does not matter there
  def blocked_sides_of((column, row), floor)
    NEIGHBOUR_OFFSETS.filter_map do |column_offset, row_offset|
      neighbour_key = "#{column + column_offset},#{row + row_offset}"
      neighbour = floors[neighbour_key]
      next unless neighbour

      side_key = ["#{column},#{row}", neighbour_key].sort.join("|")
      side_key if @layout["edges"].to_h[side_key] != DOOR && walled?(floor, neighbour)
    end
  end

  # Like map_editor/map_renderer.js (collectSides): towards open air, a floor walls itself unless it is open air or
  # water itself; between two other floors, the stone wall of a paving stops, where only one of them is paved
  def walled?(floor, neighbour)
    return floor.walls_block? if neighbour.open? && !floor.air?
    return neighbour.walls_block? if floor.open? && !neighbour.air?

    floor.stone_walls? != neighbour.stone_walls?
  end

  def cell_position(cell_key)
    cell_key.to_s.split(",").map(&:to_i)
  end
end
