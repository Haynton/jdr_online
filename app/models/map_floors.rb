# The registry of the floors of a drawn map (the cells the game master paints in the map editor), one class per floor
# in app/models/map_floors, its twin that draws it in app/javascript/map_floors. A new floor: its class, its line in
# ALL, its JavaScript module, its name in map_templates.floors (fr.yml and en.yml)
module MapFloors
  ALL = [
    MapFloors::Room, MapFloors::Stone, MapFloors::Enclosure, MapFloors::Water, MapFloors::Outdoors, MapFloors::OpenAir
  ].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  # The floor of that key, nil for a key the registry does not know
  def self.find(key)
    all.find { |floor| floor.key == key }
  end
end
