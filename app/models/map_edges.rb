# The registry of the edges of a drawn map (what the game master puts on the side between two cells: walls, doors),
# one class per edge in app/models/map_edges, its twin that draws it in app/javascript/map_edges. A new edge: its
# class, its line in ALL, its JavaScript module, its name in map_templates.edges (fr.yml and en.yml)
module MapEdges
  ALL = [MapEdges::Wall, MapEdges::StoneWall, MapEdges::LowWall, MapEdges::Door].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  # The edge of that key, nil for a key the registry does not know
  def self.find(key)
    all.find { |edge| edge.key == key }
  end
end
