require "test_helper"

# How a map is made (MapLayouts::PictureCheck, called by MapLayoutValidator): drawn or on a picture of one's own, and
# how its picture sits under the grid. Both optional: a map drawn before the pictures stays valid
class PictureCheckTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "cartographer@example.com", username: "cartographer", password: TEST_PASSWORD)
  end

  test "a map drawn, or on a picture with its settings, is accepted" do
    assert map_with({}).valid?
    assert map_with("mode" => "draw").valid?
    assert map_with("mode" => "picture", "picture" => settings).valid?
    assert map_with("mode" => "picture").valid?, "the picture not set yet"
  end

  test "an unknown mode is refused" do
    map = map_with("mode" => "painting").tap(&:validate)

    assert map.errors.of_kind?(:layout, :unknown_mode)
  end

  test "settings of the wrong form or out of their bounds are refused" do
    [settings.except("opacity"), settings.merge("zoom" => 2), settings.merge("cells_wide" => 0),
     settings.merge("cells_wide" => "28"), settings.merge("opacity" => 0), settings.merge("offset_x" => 20_000),
     "big"].each do |picture|
      map = map_with("mode" => "picture", "picture" => picture).tap(&:validate)
      assert map.errors.of_kind?(:layout, :invalid_picture), picture.inspect
    end
  end

  private

  def settings
    MapTemplate.picture_settings_for(28)
  end

  def map_with(picture_keys)
    MapTemplate.new(owner: @owner, name: "Grotte", layout: MapTemplate::BLANK_LAYOUT.merge(picture_keys))
  end
end
