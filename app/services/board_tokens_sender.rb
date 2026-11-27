class BoardTokensSender
  PLAYER_TOKENS_ID = "game-room-board-tokens-player".freeze
  GAME_MASTER_TOKENS_ID = "game-room-board-tokens-game-master".freeze
  OWN_TOKENS_ID = "game-room-board-own-tokens".freeze

  def self.tokens_id(game_master:)
    game_master ? GAME_MASTER_TOKENS_ID : PLAYER_TOKENS_ID
  end

  def initialize(game_table)
    @game_table = game_table
  end

  def call(changed_characters = [])
    Turbo::StreamsChannel.broadcast_replace_to(
      @game_table,
      target: PLAYER_TOKENS_ID,
      partial: "game_rooms/board_tokens",
      locals: { game_map: @game_table.board_game_map, game_master: false }
    )
    send_own_tokens_to(changed_characters.select(&:pc?).filter_map(&:participation))
  end

  def send_own_tokens_to_every_player
    send_own_tokens_to(@game_table.participations.accepted.player)
  end

  private

  def send_own_tokens_to(participations)
    participations.each do |participation|
      Turbo::StreamsChannel.broadcast_replace_to(
        @game_table, participation,
        target: OWN_TOKENS_ID,
        partial: "game_rooms/board_own_tokens",
        locals: { game_table: @game_table, participation: }
      )
    end
  end
end
