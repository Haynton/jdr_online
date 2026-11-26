class BoardMapChanger
  PLAYER_BOARD_ID = "game-room-board-player".freeze
  GAME_MASTER_BOARD_ID = "game-room-board-game-master".freeze

  def self.board_id(game_master:)
    game_master ? GAME_MASTER_BOARD_ID : PLAYER_BOARD_ID
  end

  def initialize(game_table, game_map)
    @game_table = game_table
    @game_map = game_map
  end

  def call
    GameTable.transaction do
      @game_table.update!(board_game_map: @game_map)
      BoardTokenCopier.new(@game_map).call if @game_map
    end
    send_board_to_players
  end

  private

  def send_board_to_players
    Turbo::StreamsChannel.broadcast_replace_to(
      @game_table,
      target: PLAYER_BOARD_ID,
      partial: "game_rooms/board",
      locals: { game_table: @game_table, game_master: false }
    )
  end
end
