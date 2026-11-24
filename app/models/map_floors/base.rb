module MapFloors
  # What every floor shares: its key, the word the layout stores for a cell painted with it
  class Base
    def key
      self.class::KEY
    end
  end
end
