require "test_helper"

# The maps ready to use of the map editor (MapPresets): one file per key, each a valid drawing for its grid, named
# in both languages
class MapPresetsTest < ActiveSupport::TestCase
  test "each key has its file, and each file its key" do
    files = MapPresets::FOLDER.glob("*.json").map { |path| path.basename(".json").to_s }

    assert_equal MapPresets::KEYS.sort, files.sort
  end

  test "each preset is a drawing a saved map accepts" do
    owner = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD)
    MapPresets.all.each do |preset|
      map = MapTemplate.new(owner:, name: preset.key, columns: preset.columns, rows: preset.rows, layout: preset.layout)

      assert map.valid?, "#{preset.key}: #{map.errors.full_messages.to_sentence}"
      assert_predicate preset.layout["floors"], :present?, preset.key
    end
  end

  test "each preset has its name and its description in both languages" do
    MapPresets::KEYS.product(%i[fr en]).each do |key, locale|
      %w[name description].each do |text|
        assert I18n.exists?("map_templates.presets.#{key}.#{text}", locale), "#{locale}: #{key} #{text}"
      end
    end
  end

  test "an unknown key finds nothing" do
    assert_nil MapPresets.find("castle_in_the_air")
    inn = MapPresets.find("inn")
    assert_equal [28, 21], [inn.columns, inn.rows]
  end
end
