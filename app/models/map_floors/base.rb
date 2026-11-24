module MapFloors
  # What every floor shares: its key, the word the layout stores for a cell painted with it, and what its sides do to
  # the tokens of the board (MapPassage), read from how its twin draws them (app/javascript/map_floors and
  # map_editor/map_renderer.js): changing one means changing the other. By default a floor is crossed, its sides too
  class Base
    def key
      self.class::KEY
    end

    # The wall the floor draws by itself where it meets the empty ground or open air stops a token (Anthony's
    # decision: the walls of a room and of stones; the low wall of an enclosure, the bank of water and the rocks of the
    # outside are crossed)
    def walls_block?
      false
    end

    # The floor draws a stone wall between it and any other floor (wallKey "stone_wall" of its twin)
    def stone_walls?
      false
    end

    # Open air: for a walled floor, it counts as the outside (open of its twin)
    def open?
      false
    end

    # Open air or water: a walled floor next to it does not wall itself in (isAir of map_floors)
    def air?
      open?
    end
  end
end
