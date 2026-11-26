module GameTables
  class BoardClearingsController < ApplicationController
    include TableOfGameMaster
    include BoardMapOfTable

    before_action :set_board_map

    def create
      @board_map.board_tokens.delete_all
      send_tokens_to_players
      @game_room = GameRoom.new(current_user.participations.find_by!(game_table: @game_table))
      respond_to do |format|
        format.turbo_stream { render :show }
        format.html { redirect_to game_table_path(@game_table) }
      end
    end
  end
end
