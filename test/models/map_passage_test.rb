require "test_helper"

# What stops a token on a map of a table (MapPassage): the empty ground and the cells painted, the walls a room or
# stones draw by themselves; never what the game master puts by hand, nor water
class MapPassageTest < ActiveSupport::TestCase
  test "the empty ground and the painted cells are blocked, the floors and the water are not" do
    passage = passage_of(floors: { "0,0" => "room", "1,0" => "water", "0,1" => "outdoors" }, blocked: ["1,0"])

    assert_equal [[1, 0], [1, 1]], passage.blocked_cells
  end

  test "the wall of a room or of stones towards open air stops a token; a door in it, the low wall, the bank do not" do
    floors = { "0,0" => "room", "1,0" => "open_air", "0,2" => "stone", "1,2" => "open_air",
               "0,4" => "enclosure", "1,4" => "open_air", "0,6" => "room", "1,6" => "open_air",
               "0,8" => "water", "1,8" => "open_air" }
    passage = passage_of(floors:, edges: { "0,6|1,6" => "door" })

    assert_equal ["0,0|1,0", "0,2|1,2"], passage.blocked_sides
  end

  test "stones wall themselves from any other floor; walls put by hand stop nothing" do
    floors = { "0,0" => "stone", "1,0" => "room", "0,1" => "room", "1,1" => "room", "2,1" => "outdoors" }
    passage = passage_of(floors:, edges: { "0,1|1,1" => "wall", "1,1|2,1" => "stone_wall" })

    assert_equal ["0,0|0,1", "0,0|1,0"], passage.blocked_sides
  end

  test "on a map played on a picture, only the painted cells are blocked" do
    passage = passage_of(floors: {}, blocked: ["2,3"], mode: "picture")

    assert_equal [[2, 3]], passage.blocked_cells
    assert_empty passage.blocked_sides
  end

  test "a step to the side costs 1, never into a blocked cell nor across a wall" do
    passage = passage_of(floors: room_floors(3, 3, walled: { "1,1" => "stone" }), blocked: ["2,0"], size: [3, 3])

    assert_equal 1, passage.step_cost([0, 0], [1, 0])
    assert_nil passage.step_cost([1, 0], [2, 0])
    assert_nil passage.step_cost([1, 0], [1, 1])
  end

  test "a diagonal step costs 1 with both ways around free, 2 around the corner of a wall, never between two walls" do
    open_floor = passage_of(floors: room_floors(2, 2))
    assert_equal 1, open_floor.step_cost([0, 0], [1, 1])

    one_wall = passage_of(floors: room_floors(2, 2, walled: { "1,0" => "stone" }))
    assert_equal 2, one_wall.step_cost([0, 0], [1, 1])

    two_walls = passage_of(floors: room_floors(2, 2, walled: { "1,0" => "stone", "0,1" => "stone" }))
    assert_nil two_walls.step_cost([0, 0], [1, 1])
  end

  test "the cheapest way goes around a wall; none leads into a walled room" do
    floors = room_floors(5, 3, walled: { "2,0" => "stone", "2,1" => "stone" })
    around = passage_of(floors:, size: [5, 3])
    assert_equal 6, around.path_cost([0, 0], [4, 0])
    assert_equal 0, around.path_cost([0, 0], [0, 0])

    closed = passage_of(floors: floors.merge("2,2" => "stone"), size: [5, 3])
    assert_nil closed.path_cost([0, 0], [4, 0])
  end

  private

  # A room of floors, some cells turned into stones (which wall themselves from any other floor)
  def room_floors(columns, rows, walled: {})
    (0...columns).to_a.product((0...rows).to_a).to_h { |column, row| ["#{column},#{row}", "room"] }.merge(walled)
  end

  def passage_of(floors:, edges: {}, blocked: [], mode: "draw", size: [2, 2])
    layout = MapTemplate::BLANK_LAYOUT.merge("floors" => floors, "edges" => edges, "blocked" => blocked, "mode" => mode)
    MapPassage.new(GameMap.new(columns: size.first, rows: size.last, layout:))
  end
end
