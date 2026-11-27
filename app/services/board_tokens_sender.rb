class BoardTokensSender
  PLAYER_TOKENS_ID = "game-room-board-tokens-player".freeze
  GAME_MASTER_TOKENS_ID = "game-room-board-tokens-game-master".freeze

  def self.tokens_id(game_master:)
    game_master ? GAME_MASTER_TOKENS_ID : PLAYER_TOKENS_ID
  end

  def initialize(game_table)
    @game_table = game_table
  end

  def call
    Turbo::StreamsChannel.broadcast_replace_to(
      @game_table,
      target: PLAYER_TOKENS_ID,
      partial: "game_rooms/board_tokens",
      locals: { game_map: @game_table.board_game_map, game_master: false }
    )
  end
end
