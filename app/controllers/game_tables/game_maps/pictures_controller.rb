module GameTables
  module GameMaps
    # The picture of a map copied into a table, played on a picture of one's own (ChangesMapPicture): a picture of the
    # copy, the original keeps its own. Only on a map of a table of the game master (DrawnMapOfTable)
    class PicturesController < ApplicationController
      include ChangesMapPicture
      include DrawnMapOfTable

      def create
        attach_map_picture(@game_map, edit_game_table_game_map_path(@game_table, @game_map))
      end

      def destroy
        remove_map_picture(@game_map, edit_game_table_game_map_path(@game_table, @game_map))
      end
    end
  end
end
