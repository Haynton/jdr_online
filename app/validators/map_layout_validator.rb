# Checks the drawing of a map (its layout, JSONB, written by the map editor) against its grid: JSONB has no check of
# its own in the database, and a layout sent by hand must not break the editor nor the board.
#
#   { "version" => 1,
#     "floors" => { "3,4" => "room" },            # a cell "column,row" and its floor (MapFloors)
#     "edges" => { "3,4|4,4" => "wall" },         # two neighbouring cells, in sorted order, and their edge (MapEdges)
#     "objects" => [{ "key" => "table", "column" => 3, "row" => 4, "rotation" => 1 }],    # MapLayouts::ObjectsCheck
#     "mode" => "picture",                                     # drawn (draw) or played on a picture: PictureCheck
#     "picture" => { "cells_wide" => 28, "offset_x" => 0, "offset_y" => 0, "opacity" => 1 },
#     "blocked" => ["3,4"],         # cells painted with the brush « Zones bloquantes » (a map of a table: MapPassage)
#     "tokens" => [{ "character_id" => 12, "column" => 3, "row" => 4 }] }    # a map of a table: TokensCheck
#
# "objects" may be missing (a drawing saved before the objects), "mode" and "picture" too (a map drawn), "blocked" and
# "tokens" too (nothing painted or put, and every map of « Mes cartes »).
#
# The errors go on :layout. Only the first wrong cell and the first wrong edge are told: a broken layout could hold
# hundreds of them
class MapLayoutValidator < ActiveModel::Validator
  CURRENT_VERSION = 1
  LAYOUT_KEYS = %w[version floors edges objects mode picture blocked tokens].freeze
  CELL_FORMAT = /\A(\d+),(\d+)\z/

  def validate(map)
    layout = map.layout
    return map.errors.add(:layout, :invalid_format) unless well_formed?(layout)

    validate_floors(map, layout["floors"])
    validate_edges(map, layout["edges"])
    validate_objects(map, layout.fetch("objects", []))
    validate_picture(map, layout)
    validate_blocked(map, layout.fetch("blocked", []))
    validate_tokens(map, layout.fetch("tokens", []))
  end

  private

  def well_formed?(layout)
    layout.is_a?(Hash) && (layout.keys - LAYOUT_KEYS).empty? && layout["version"] == CURRENT_VERSION &&
      layout["floors"].is_a?(Hash) && layout["edges"].is_a?(Hash) && layout.fetch("objects", []).is_a?(Array) &&
      layout.fetch("tokens", []).is_a?(Array)
  end

  def validate_floors(map, floors)
    cell, floor = floors.find { |cell_key, floor_key| !inside?(map, cell_key) || MapFloors.find(floor_key).nil? }
    return if cell.nil?
    return map.errors.add(:layout, :cell_outside_grid, cell:) unless inside?(map, cell)

    map.errors.add(:layout, :unknown_floor, floor:)
  end

  def validate_edges(map, edges)
    side, edge = edges.find { |side_key, edge_key| !valid_side?(map, side_key) || MapEdges.find(edge_key).nil? }
    return if side.nil?
    return map.errors.add(:layout, :invalid_edge_side, side:) unless valid_side?(map, side)

    map.errors.add(:layout, :unknown_edge, edge:)
  end

  # A list of cells of the grid, each one once
  def validate_blocked(map, blocked_cells)
    unless blocked_cells.is_a?(Array) && blocked_cells.uniq == blocked_cells
      return map.errors.add(:layout, :invalid_blocked)
    end

    cell = blocked_cells.find { |cell_key| !inside?(map, cell_key) }
    map.errors.add(:layout, :cell_outside_grid, cell:) if cell
  end

  def validate_picture(map, layout)
    error_type, error_options = MapLayouts::PictureCheck.new(layout).call
    map.errors.add(:layout, error_type, **error_options) if error_type
  end

  def validate_tokens(map, tokens)
    error_type, error_options = MapLayouts::TokensCheck.new(map, tokens).call
    map.errors.add(:layout, error_type, **error_options) if error_type
  end

  def validate_objects(map, objects)
    error_type, error_options = MapLayouts::ObjectsCheck.new(map, objects).call
    map.errors.add(:layout, error_type, **error_options) if error_type
  end

  def inside?(map, cell_key)
    column, row = cell_position(cell_key)
    return false if column.nil?

    column < map.columns.to_i && row < map.rows.to_i
  end

  # Two cells of the grid that share a side, written once: in sorted order, like the editor writes them
  def valid_side?(map, side_key)
    cells = side_key.to_s.split("|")
    return false unless cells.size == 2 && cells == cells.sort && cells.all? { |cell_key| inside?(map, cell_key) }

    neighbours?(*cells.map { |cell_key| cell_position(cell_key) })
  end

  def neighbours?(first_position, second_position)
    column_gap = (first_position[0] - second_position[0]).abs
    row_gap = (first_position[1] - second_position[1]).abs
    column_gap + row_gap == 1
  end

  def cell_position(cell_key)
    match = CELL_FORMAT.match(cell_key.to_s)
    match && [match[1].to_i, match[2].to_i]
  end
end
