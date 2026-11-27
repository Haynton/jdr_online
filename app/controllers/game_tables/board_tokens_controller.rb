module GameTables
  class BoardTokensController < ApplicationController
    include TableOfGameMaster
    include BoardMapOfTable

    before_action :set_board_map

    def create
      character = @game_table.characters.placeable_on_the_board.find(params.require(:character_id))
      token = @board_map.board_tokens.build(character:, column: params[:column], row: params[:row],
                                            hidden: BoardToken.hidden_at_first?(character))
      return head :unprocessable_content unless token.save_on_its_cell

      answer_with_the_tokens
    end

    def update
      token = @board_map.board_tokens.find(params[:id])
      return head :unprocessable_content unless token.update(params.permit(:hidden, :name))

      answer_with_the_tokens
    end

    def destroy
      @board_map.board_tokens.find(params[:id]).destroy!
      answer_with_the_tokens
    end

    private

    def answer_with_the_tokens
      send_tokens_to_players
      render :show, formats: :turbo_stream
    end
  end
end
