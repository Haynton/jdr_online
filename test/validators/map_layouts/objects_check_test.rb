require "test_helper"

# The objects of a drawing (MapLayouts::ObjectsCheck, called by MapLayoutValidator) and their registry (MapObjects):
# known, on the floor, inside the grid once turned, never on another object; each one drawn by its JavaScript twin
class ObjectsCheckTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "cartographer@example.com", username: "cartographer", password: TEST_PASSWORD)
  end

  test "objects on floor cells, turned, side by side, are accepted" do
    objects = [placed("bed", 0, 0, rotation: 1), placed("table", 1, 0), placed("large_table", 2, 1)]
    map = map_with(floors: floor_rectangle(4, 3), objects:)

    assert map.valid?, map.errors.full_messages.to_sentence
  end

  test "a drawing saved before the objects, without their list, stays valid" do
    map = map_with(floors: { "0,0" => "room" })
    map.layout.delete("objects")

    assert map.valid?
  end

  test "an object of the wrong form is refused" do
    [placed("table", 0, 0).merge("color" => "red"), placed("table", 0, 0, rotation: 4), placed("table", "0", 0),
     "table"].each do |placed_object|
      map = map_with(floors: floor_rectangle(2, 2), objects: [placed_object])
      assert map.tap(&:validate).errors.of_kind?(:layout, :invalid_object), placed_object.inspect
    end
  end

  test "an object the registry does not know is refused" do
    map = map_with(floors: floor_rectangle(2, 2), objects: [placed("dragon", 0, 0)])

    assert map.tap(&:validate).errors.of_kind?(:layout, :unknown_object)
  end

  test "an object whose cells, once turned, go out of the grid is refused" do
    map = map_with(floors: floor_rectangle(10, 10), objects: [placed("bed", 9, 0)])
    assert map.tap(&:validate).errors.of_kind?(:layout, :object_outside_grid)

    turned = map_with(floors: floor_rectangle(10, 10), objects: [placed("bed", 9, 0, rotation: 1)])
    assert turned.valid?
  end

  test "an object off the floor, or on the cells of another one, is refused" do
    off_floor = map_with(floors: { "0,0" => "room" }, objects: [placed("bed", 0, 0)])
    assert off_floor.tap(&:validate).errors.of_kind?(:layout, :object_off_floor)

    overlapping = map_with(floors: floor_rectangle(3, 1), objects: [placed("bed", 0, 0), placed("chair", 1, 0)])
    assert overlapping.tap(&:validate).errors.of_kind?(:layout, :objects_overlap)
  end

  test "every object has its JavaScript twin, of the same size, in the file of its family" do
    MapObjects::ALL.each do |map_object|
      drawings = Rails.root.join("app/javascript/map_objects/#{map_object.family}.js").read
      twin = /^  #{map_object.key}: \{ width: #{map_object.width}, height: #{map_object.height}\b/
      assert_match twin, drawings, map_object.key
    end
    assert_equal 64, MapObjects.keys.uniq.size
  end

  test "every object has its name in both languages" do
    %i[fr en].each do |locale|
      MapObjects::ALL.each do |map_object|
        assert I18n.exists?("map_templates.objects.#{map_object.key}", locale), map_object.key
      end
    end
  end

  test "an object off the floor is named in the words of the page" do
    I18n.with_locale(:fr) do
      off_floor = map_with(floors: { "0,0" => "room" }, objects: [placed("bed", 0, 0)]).tap(&:validate)
      assert_includes off_floor.errors.full_messages.to_sentence, "Lit"
    end
  end

  private

  def map_with(floors: {}, objects: [])
    layout = MapTemplate::BLANK_LAYOUT.merge("floors" => floors, "objects" => objects)
    MapTemplate.new(name: "Carte", owner: @owner, columns: 10, rows: 10, layout:)
  end

  def floor_rectangle(columns, rows)
    columns.times.flat_map { |column| rows.times.map { |row| ["#{column},#{row}", "room"] } }.to_h
  end

  def placed(key, column, row, rotation: 0)
    { "key" => key, "column" => column, "row" => row, "rotation" => rotation }
  end
end
