require "test_helper"

class MapLayoutValidatorTest < ActiveSupport::TestCase
  setup do
    @owner = create_user("cartographer")
  end

  test "floors and edges of the registries, on the grid, are accepted" do
    map = map_with(floors: { "0,0" => "room", "1,0" => "stone", "9,9" => "water" },
                   edges: { "0,0|1,0" => "door", "0,0|0,1" => "wall" })

    assert map.valid?
  end

  test "a layout without its version, or with something else, is refused" do
    refused = [nil, [], { "floors" => {}, "edges" => {} }, MapTemplate::BLANK_LAYOUT.merge("tokens" => []),
               MapTemplate::BLANK_LAYOUT.merge("floors" => [])]

    refused.each do |layout|
      map = MapTemplate.new(name: "Carte", owner: @owner, columns: 10, rows: 10, layout:)
      assert map.tap(&:validate).errors.of_kind?(:layout, :invalid_format), layout.inspect
    end
  end

  test "a cell outside the grid is refused" do
    ["10,0", "0,10", "-1,0", "a,b", "1,2,3"].each do |cell|
      map = map_with(floors: { cell => "room" })
      assert map.tap(&:validate).errors.of_kind?(:layout, :cell_outside_grid), cell
    end
  end

  test "a floor the registry does not know is refused" do
    map = map_with(floors: { "0,0" => "lava" })

    assert map.tap(&:validate).errors.of_kind?(:layout, :unknown_floor)
    assert_includes map.errors.full_messages.to_sentence, "lava"
  end

  test "an edge is between two neighbouring cells, written in sorted order" do
    ["0,0|2,0", "0,0|1,1", "1,0|0,0", "0,0", "0,0|1,0|2,0", "9,9|9,10"].each do |side|
      map = map_with(edges: { side => "wall" })
      assert map.tap(&:validate).errors.of_kind?(:layout, :invalid_edge_side), side
    end
  end

  test "an edge the registry does not know is refused" do
    map = map_with(edges: { "0,0|1,0" => "portcullis" })

    assert map.tap(&:validate).errors.of_kind?(:layout, :unknown_edge)
  end

  test "every floor and every edge of the registries has a unique key" do
    assert_equal MapFloors.keys.uniq, MapFloors.keys
    assert_equal MapEdges.keys.uniq, MapEdges.keys
    assert_nil MapFloors.find("lava")
  end

  private

  def map_with(floors: {}, edges: {})
    layout = MapTemplate::BLANK_LAYOUT.merge("floors" => floors, "edges" => edges)
    MapTemplate.new(name: "Carte", owner: @owner, columns: 10, rows: 10, layout:)
  end

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD)
  end
end
