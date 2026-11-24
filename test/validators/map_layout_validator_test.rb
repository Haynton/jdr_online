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
    refused = [nil, [], { "floors" => {}, "edges" => {} }, MapTemplate::BLANK_LAYOUT.merge("pawns" => []),
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

  test "the blocked zones are cells of the grid, each one once" do
    accepted = MapTemplate.new(name: "Carte", owner: @owner, columns: 10, rows: 10,
                               layout: MapTemplate::BLANK_LAYOUT.merge("blocked" => ["0,0", "9,9"]))
    assert accepted.valid?

    refused = { ["0,10"] => :cell_outside_grid, ["1,1", "1,1"] => :invalid_blocked, "1,1" => :invalid_blocked }
    refused.each do |blocked, error|
      map = MapTemplate.new(name: "Carte", owner: @owner, columns: 10, rows: 10,
                            layout: MapTemplate::BLANK_LAYOUT.merge("blocked" => blocked))
      assert map.tap(&:validate).errors.of_kind?(:layout, error), blocked.inspect
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

  test "every floor and every edge has its JavaScript twin, listed in the index" do
    { "map_floors" => MapFloors, "map_edges" => MapEdges }.each do |folder, registry|
      index = Rails.root.join("app/javascript/#{folder}/index.js").read
      registry.all.map(&:key).each do |key|
        assert_predicate Rails.root.join("app/javascript/#{folder}/#{key}.js"), :exist?, key
        assert_includes index, "#{key}:", key
      end
    end
  end

  test "every floor and every edge has its name in both languages" do
    %i[fr en].each do |locale|
      MapFloors.all.each { |floor| assert I18n.exists?("map_templates.floors.#{floor.key}", locale), floor.key }
      MapEdges.all.each { |edge| assert I18n.exists?("map_templates.edges.#{edge.key}", locale), edge.key }
    end
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
