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
#
# The moves of a player's token (decision of 27 November), one step to one of the eight cells around: never into a
# blocked cell nor across a blocked side; a diagonal step costs 1 when both ways around its corner are free, 2 when it
# goes around the corner of a wall (only one of them free), and is refused when neither is. Twin of
# map_editor/board_moves.js: changing one is changing the other
class MapPassage
  DOOR = "door".freeze
  # The four neighbours of a cell
  NEIGHBOUR_OFFSETS = [[1, 0], [-1, 0], [0, 1], [0, -1]].freeze
  # The eight cells around a cell, for a move
  STEP_OFFSETS = [-1, 0, 1].product([-1, 0, 1]) - [[0, 0]]
  # The cost of a diagonal step, by how many ways around its corner are free
  DIAGONAL_COSTS = { 2 => 1, 1 => 2 }.freeze

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

  # The cost of one step to a neighbouring cell, nil when it is refused
  def step_cost(from, to)
    return if blocked_cell?(to)
    return (side_open?(from, to) ? 1 : nil) if from[0] == to[0] || from[1] == to[1]

    corners = [[to[0], from[1]], [from[0], to[1]]]
    DIAGONAL_COSTS[corners.count { |corner| way_around_open?(from, corner, to) }]
  end

  # The cost of the cheapest way from a cell to another, step by step (each cost is a whole number: the cells are taken
  # by increasing cost, Dial's algorithm), nil when no way leads there
  def path_cost(from, to)
    best_costs = { from => 0 }
    cells_by_cost = [[from]]
    cells_by_cost.each_with_index do |cells, cost|
      Array(cells).each do |cell|
        return cost if cell == to

        reach_neighbours(cell, cost, best_costs, cells_by_cost) if best_costs[cell] == cost
      end
    end
    nil
  end

  private

  def reach_neighbours(cell, cost, best_costs, cells_by_cost)
    steps_from(cell).each do |neighbour, step|
      reached = cost + step
      next if best_costs.fetch(neighbour, Float::INFINITY) <= reached

      best_costs[neighbour] = reached
      (cells_by_cost[reached] ||= []) << neighbour
    end
  end

  def steps_from((column, row))
    STEP_OFFSETS.filter_map do |column_offset, row_offset|
      neighbour = [column + column_offset, row + row_offset]
      next unless inside?(neighbour)

      cost = step_cost([column, row], neighbour)
      [neighbour, cost] if cost
    end
  end

  def way_around_open?(from, corner, to)
    !blocked_cell?(corner) && side_open?(from, corner) && side_open?(corner, to)
  end

  def blocked_cell?(cell)
    @blocked_cell_set ||= blocked_cells.to_set
    @blocked_cell_set.include?(cell)
  end

  def side_open?(cell, neighbour)
    @blocked_side_set ||= blocked_sides.to_set
    !@blocked_side_set.include?([cell, neighbour].map { |position| position.join(",") }.sort.join("|"))
  end

  def inside?((column, row))
    column.between?(0, @columns - 1) && row.between?(0, @rows - 1)
  end

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
