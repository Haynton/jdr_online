module GameTables
  class BoardTokensController < ApplicationController
    include TableOfGameMaster
    include BoardMapOfTable

    before_action :set_board_map

    def create
      creature = @game_table.npcs.find(params.require(:character_id))
      token = @board_map.board_tokens.build(character: creature, column: params[:column], row: params[:row])
      return head :unprocessable_content unless token.save

      answer_with_the_tokens
    end

    def update
      token = @board_map.board_tokens.find(params[:id])
      token.update!(hidden: ActiveModel::Type::Boolean.new.cast(params.require(:hidden)))
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
