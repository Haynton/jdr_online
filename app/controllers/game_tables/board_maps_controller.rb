module GameTables
  class BoardMapsController < ApplicationController
    include TableOfGameMaster

    def update
      drawn_map = @game_table.game_maps.where.not(layout: nil).find(params.require(:game_map_id))
      BoardMapChanger.new(@game_table, drawn_map).call
      answer_with_the_board
    end

    def destroy
      BoardMapChanger.new(@game_table, nil).call
      answer_with_the_board
    end

    private

    def answer_with_the_board
      @game_room = GameRoom.new(current_user.participations.find_by!(game_table: @game_table))
      respond_to do |format|
        format.turbo_stream { render :show }
        format.html { redirect_to game_table_path(@game_table) }
      end
    end
  end
end
