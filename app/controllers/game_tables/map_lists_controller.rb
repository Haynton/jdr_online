# The fifth step of a table: its maps (decision: an empty list at first). Each one is a map of the table (GameMap),
# added and changed in its window (GameTables::GameMapsController). Everything is saved as it is done: Continue only
# opens the next step (the summary), and reaches it on a draft
module GameTables
  class MapListsController < ApplicationController
    include TableOfGameMaster

    def edit
      @game_maps = @game_table.game_maps.with_attached_image
    end

    def update
      @game_table.reach_creation_step(GameTable.next_creation_step("maps"))
      # For screen readers only: the next step shows
      redirect_to game_table_summary_path(@game_table), flash: { screen_reader_notice: t(".saved") }
    end
  end
end
