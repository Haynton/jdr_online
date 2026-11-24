module MapEdges
  # What every edge shares: its key, the word the layout stores for the side between two cells
  class Base
    def key
      self.class::KEY
    end
  end
end
