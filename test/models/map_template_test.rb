require "test_helper"

class MapTemplateTest < ActiveSupport::TestCase
  setup do
    @owner = create_user("cartographer")
  end

  test "a new map has a name, the default grid and nothing drawn" do
    map_template = MapTemplate.new(name: "La taverne", owner: @owner)

    assert map_template.valid?
    assert_equal [28, 21], [map_template.columns, map_template.rows]
    assert_equal MapTemplate::BLANK_LAYOUT, map_template.layout
  end

  test "a map needs a name of 60 characters at most" do
    assert MapTemplate.new(name: "", owner: @owner).tap(&:validate).errors.of_kind?(:name, :blank)

    too_long = MapTemplate.new(name: "a" * (MapTemplate::NAME_MAX_LENGTH + 1), owner: @owner)
    assert too_long.tap(&:validate).errors.of_kind?(:name, :too_long)
  end

  test "the grid has from 10 to 60 columns and rows, like in the database" do
    assert MapTemplate.new(name: "Petite", owner: @owner, columns: 9).tap(&:validate).errors.of_kind?(:columns, :in)
    assert MapTemplate.new(name: "Grande", owner: @owner, rows: 61).tap(&:validate).errors.of_kind?(:rows, :in)
    assert MapTemplate.new(name: "Juste", owner: @owner, columns: 10, rows: 60).valid?
  end

  test "the maps of a game master go with their account" do
    MapTemplate.create!(name: "La taverne", owner: @owner)

    assert_difference -> { MapTemplate.count }, -1 do
      @owner.destroy
    end
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD)
  end
end
