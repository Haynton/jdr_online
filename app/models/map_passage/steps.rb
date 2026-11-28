class MapPassage
  # The moves of a player's token (decision of 27 November), one step to one of the eight cells around: never into a
  # blocked cell nor across a blocked side; a diagonal step costs 1 when both ways around its corner are free, 2 when
  # it goes around the corner of a wall (only one of them free), and is refused when neither is. Twin of
  # map_editor/board_moves.js: changing one is changing the other. Part of MapPassage (its blocked cells and sides)
  module Steps
    # The eight cells around a cell, the straight steps first: among ways of the same cost, the straightest is taken
    STEP_OFFSETS = (NEIGHBOUR_OFFSETS + [[1, 1], [1, -1], [-1, 1], [-1, -1]]).freeze
    # The cost of a diagonal step, by how many ways around its corner are free
    DIAGONAL_COSTS = { 2 => 1, 1 => 2 }.freeze

    # The cost of one step to a neighbouring cell, nil when it is refused
    def step_cost(from, to)
      return if blocked_cell?(to)
      return (side_open?(from, to) ? 1 : nil) if from[0] == to[0] || from[1] == to[1]

      corners = [[to[0], from[1]], [from[0], to[1]]]
      DIAGONAL_COSTS[corners.count { |corner| way_around_open?(from, corner, to) }]
    end

    # The cost of the cheapest way from a cell to another, nil when no way leads there
    def path_cost(from, to)
      cheapest_way(from, to)&.last
    end

    # The cells of the cheapest way from a cell to another, both included, nil when no way leads there
    def path(from, to)
      cheapest_way(from, to)&.first
    end

    private

    # [cells, cost] of the cheapest way, step by step (each cost is a whole number: the cells are taken by increasing
    # cost, Dial's algorithm), each cell reached remembering the one it was reached from
    def cheapest_way(from, to)
      search = { best_costs: { from => 0 }, previous: {}, cells_by_cost: [[from]] }
      search[:cells_by_cost].each_with_index do |cells, cost|
        Array(cells).each do |cell|
          return [way_back(search[:previous], to), cost] if cell == to

          reach_neighbours(cell, cost, search) if search[:best_costs][cell] == cost
        end
      end
      nil
    end

    def way_back(previous, to)
      cells = [to]
      cells.unshift(previous[cells.first]) while previous.key?(cells.first)
      cells
    end

    def reach_neighbours(cell, cost, search)
      steps_from(cell).each do |neighbour, step|
        reached = cost + step
        next if search[:best_costs].fetch(neighbour, Float::INFINITY) <= reached

        search[:best_costs][neighbour] = reached
        search[:previous][neighbour] = cell
        (search[:cells_by_cost][reached] ||= []) << neighbour
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
  end
end
