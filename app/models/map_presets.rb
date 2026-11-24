# The maps ready to use of the map editor (its tab Templates), from the prototype (docs/prototypes/map-editor.html):
# a game master starts from one instead of an empty grid. Each one is a file in config/map_presets, named by its key:
# the size of its grid and its drawing, in the format of a saved map (MapLayoutValidator, checked by a test). Its name
# and its description in map_templates.presets (fr.yml and en.yml). A new one: its file, its key here, its texts
module MapPresets
  MapPreset = Data.define(:key, :columns, :rows, :layout)
  # In the order of the tab: from the simplest (a clearing) to the largest buildings
  KEYS = %w[camp river_cabin inn throne_room manor].freeze
  FOLDER = Rails.root.join("config/map_presets")

  def self.all
    @all ||= KEYS.map { |key| read(key) }.freeze
  end

  # The preset of that key, nil for a key the registry does not know
  def self.find(key)
    all.find { |preset| preset.key == key }
  end

  def self.read(key)
    data = JSON.parse(FOLDER.join("#{key}.json").read(encoding: "UTF-8"))
    MapPreset.new(key:, columns: data["columns"], rows: data["rows"], layout: data["layout"])
  end
  private_class_method :read
end
