module BoardMapOfTable
  extend ActiveSupport::Concern

  private

  def set_board_map
    @board_map = @game_table.board_game_map or raise ActiveRecord::RecordNotFound
  end

  def send_tokens_to_players
    BoardTokensSender.new(@game_table).call
  end
end
