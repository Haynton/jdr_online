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

  private

  def passage_of(floors:, edges: {}, blocked: [], mode: "draw")
    layout = MapTemplate::BLANK_LAYOUT.merge("floors" => floors, "edges" => edges, "blocked" => blocked, "mode" => mode)
    MapPassage.new(GameMap.new(columns: 2, rows: 2, layout:))
  end
end
