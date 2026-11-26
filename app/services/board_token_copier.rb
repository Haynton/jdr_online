class BoardTokenCopier
  def initialize(game_map)
    @game_map = game_map
  end

  def call
    return if @game_map.tokens_copied?

    GameMap.transaction do
      @game_map.placed_tokens.each { |placed_token| copy(placed_token) }
      @game_map.update!(tokens_copied_at: Time.current)
    end
  end

  private

  def copy(placed_token)
    BoardToken.new(game_map: @game_map, **placed_token.slice(:character, :column, :row, :hidden)).save
  end
end
