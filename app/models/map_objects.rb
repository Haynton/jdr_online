# The registry of the objects of a drawn map (the furniture, the decor and the nature the game master puts on its
# cells): each one with its key, its size in cells before it is turned, and its family (the tab Objects shows one family
# at a time). Their twins draw them in app/javascript/map_objects, one file per family, with the same size (checked by
# a test). In Ruby an object is only data: what it does to the way (Passage) will come with its own branch. A new
# object: its line here, its drawing in its family, its name in map_templates.objects (fr.yml and en.yml)
module MapObjects
  MapObject = Data.define(:key, :width, :height, :family)
  FAMILIES = %w[furniture decor nature].freeze

  # In the order of the tab, family by family, like the prototype
  SIZES_BY_FAMILY = {
    "furniture" => {
      table: [1, 1], large_table: [2, 1], long_table: [3, 1], banquet_table: [4, 2], round_table: [2, 2], chair: [1, 1],
      stool: [1, 1], bench: [2, 1], throne: [1, 1], bed: [2, 1], double_bed: [2, 2], rug: [3, 2], wardrobe: [2, 1],
      bookcase: [3, 1], shelf: [2, 1], chest: [1, 1], desk: [2, 1], counter: [3, 1], bathtub: [2, 1], fireplace: [2, 1],
      bread_oven: [2, 2], cauldron: [1, 1], brazier: [1, 1], candelabrum: [1, 1], barrel: [1, 1], crate: [1, 1],
      sacks: [1, 1], workbench: [3, 1], anvil: [1, 1], weapon_rack: [2, 1], training_dummy: [1, 1], cage: [1, 1]
    },
    "decor" => {
      column: [1, 1], statue: [1, 1], altar: [2, 1], sarcophagus: [2, 1], grave: [2, 1], fountain: [2, 2], well: [1, 1],
      stairs: [1, 1], spiral_stairs: [2, 2], ladder: [1, 1], trap: [1, 1], bones: [1, 1], cart: [2, 1]
    },
    "nature" => {
      tree: [2, 2], fir_tree: [2, 2], bush: [1, 1], fern: [1, 1], stump: [1, 1], rock: [1, 1], boulder: [2, 2],
      hay: [1, 1], puddle: [1, 1], pond: [2, 2], water_lilies: [1, 1], reeds: [1, 1], campfire: [1, 1], tent: [2, 2],
      small_bridge: [2, 1], bridge: [3, 1], long_bridge: [4, 1], wide_bridge: [3, 2], rowboat: [2, 1]
    }
  }.freeze

  ALL = SIZES_BY_FAMILY.flat_map do |family, sizes|
    sizes.map { |key, (width, height)| MapObject.new(key: key.to_s, width:, height:, family:) }
  end.freeze

  def self.keys
    ALL.map(&:key)
  end

  # The object of that key, nil for a key the registry does not know
  def self.find(key)
    ALL.find { |map_object| map_object.key == key }
  end

  def self.of_family(family)
    ALL.select { |map_object| map_object.family == family }
  end
end
