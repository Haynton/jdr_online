# A token dragged to another cell of the board (decision of 27 November): the game master moves any token, anywhere
# but on another token; a player only the token of their own character and those of its companions, and only where a
# way leads (BoardToken#reachable_by_a_player?). Only a person accepted at the table; a token they may not move is a
# 404, a cell refused a 422. The players see the new place at once (BoardTokensSender), and so does the game master
# when a player moved: the page of the game master follows only its own clicks otherwise
module GameTables
  module BoardTokens
    class MovesController < ApplicationController
      include BoardMapOfTable

      before_action :set_participation_and_token

      def update
        column, row = params.require(%i[column row]).map { |value| Integer(value, exception: false) }
        return head :unprocessable_content unless column && row && move_to(column, row)

        send_the_new_place
        @participation.game_master? ? render("game_tables/board_tokens/show", formats: :turbo_stream) : head(:ok)
      end

      private

      def set_participation_and_token
        @participation = current_user.participations.accepted.find_by!(game_table_id: params[:game_table_id])
        @game_table = @participation.game_table
        set_board_map
        @token = @board_map.board_tokens.find(params[:board_token_id])
        raise ActiveRecord::RecordNotFound unless @token.movable_by?(@participation)
      end

      def move_to(column, row)
        return false unless @participation.game_master? || @token.reachable_by_a_player?(column, row)

        @token.assign_attributes(column:, row:)
        @token.save_on_its_cell
      end

      def send_the_new_place
        sender = BoardTokensSender.new(@game_table)
        sender.call([@token.character])
        sender.send_game_master_tokens unless @participation.game_master?
      end
    end
  end
end
