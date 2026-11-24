# The step Maps of a table: its list (game_tables/map_lists/edit) and the window of one map (game_tables/game_maps).
# Like the window of an NPC, a link loads its page into the frame of its window, which frame_dialog_controller.js opens
# once it has arrived; opened directly, or without JavaScript, each address stays a whole page
module GameTables
  module MapDialogHelper
    MAP_FRAME = "map_dialog".freeze

    # Into its window, never prefetched (an answer laid out for the window must not be reused for the whole page)
    def map_dialog_link_data
      { turbo_frame: MAP_FRAME, turbo_prefetch: false }
    end

    def map_in_dialog?
      turbo_frame_request_id == MAP_FRAME
    end

    # "Grid of 50 px, shown", or hidden
    def game_map_grid_text(game_map)
      state = game_map.grid_visible ? "shown" : "hidden"
      t("game_tables.game_maps.grid.#{state}", size: game_map.grid_cell_size)
    end

    # What the file field accepts, said to the browser (the server checks it again: GameMap)
    def game_map_image_accept
      GameMap::IMAGE_CONTENT_TYPES.join(",")
    end
  end
end
