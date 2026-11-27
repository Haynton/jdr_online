class BoardMapChanger
  PLAYER_BOARD_ID = "game-room-board-player".freeze
  GAME_MASTER_BOARD_ID = "game-room-board-game-master".freeze

  def self.board_id(game_master:)
    game_master ? GAME_MASTER_BOARD_ID : PLAYER_BOARD_ID
  end

  def self.send_board(game_table, game_master: false)
    audience = game_master ? [game_table, GameTableChannel::GAME_MASTER_AUDIENCE] : [game_table]
    Turbo::StreamsChannel.broadcast_replace_to(
      *audience,
      target: board_id(game_master:),
      partial: "game_rooms/board",
      locals: { game_table:, game_master: }
    )
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
    self.class.send_board(@game_table)
    BoardTokensSender.new(@game_table).send_own_tokens_to_every_player
  end
end
