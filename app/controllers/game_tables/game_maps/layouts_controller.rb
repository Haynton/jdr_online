module GameTables
  module GameMaps
    # The drawing of a map copied into a table, saved by the map editor after each stroke (SavesMapLayout): the table
    # changes its copy, « Mes cartes » never changes. Only on a map of a table of the game master (DrawnMapOfTable)
    class LayoutsController < ApplicationController
      include SavesMapLayout
      include DrawnMapOfTable

      def update
        save_map_layout(@game_map)
      end
    end
  end
end
