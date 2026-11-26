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
    @game_table.update!(board_game_map: @game_map)
    send_board_to_players
    send_board_to_game_master
  end

  private

  def send_board_to_players
    send_board(@game_table, game_master: false)
  end

  def send_board_to_game_master
    send_board(@game_table, GameTableChannel::GAME_MASTER_AUDIENCE, game_master: true)
  end

  def send_board(*streamables, game_master:)
    Turbo::StreamsChannel.broadcast_replace_to(
      *streamables,
      target: self.class.board_id(game_master:),
      partial: "game_rooms/board",
      locals: { game_table: @game_table, game_master: }
    )
  end
end
