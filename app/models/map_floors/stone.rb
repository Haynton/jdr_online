module MapFloors
  # Paving stones, walled in stone where it meets the empty ground or open air
  class Stone < MapFloors::Base
    KEY = "stone".freeze

    def walls_block?
      true
    end

    def stone_walls?
      true
    end
  end
end
