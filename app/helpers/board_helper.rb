module BoardHelper
  ZOOM_ACTIONS = %w[
    wheel->board-zoom#zoomOrMoveWithWheel:!passive gesturestart->board-zoom#startGesture:!passive
    gesturechange->board-zoom#zoomWithGesture:!passive pointerdown->board-zoom#pressPointer
    pointermove->board-zoom#movePointer pointerup->board-zoom#releasePointer
    pointercancel->board-zoom#releasePointer pointerenter->board-zoom#enterMap pointerleave->board-zoom#leaveMap
  ].join(" ").freeze
  MOVING_KEYS_ACTIONS = %w[
    keydown.space@window->board-zoom#holdSpace keyup.space@window->board-zoom#releaseSpace
    keydown.h@window->board-zoom#toggleHandWithKey
  ].join(" ").freeze
  GAME_MASTER_ACTIONS = %w[
    pointerdown->room-board#notePointerDown click->room-board#clickBoard
    contextmenu->room-board#dropCreatureWithRightClick
  ].join(" ").freeze
  HAND_PRESSED_CLASSES = %w[
    aria-pressed:border-brass aria-pressed:bg-primary-soft aria-pressed:text-primary-soft-ink
  ].join(" ").freeze
  KEPT_FROM_PLAYERS = %w[tokens blocked].freeze
  KEPT_FROM_GAME_MASTER = %w[tokens].freeze
  TOKEN_MENU_ITEM_CLASSES = %w[
    rounded-lg px-2.5 py-2 text-left text-sm font-medium transition-colors hover:bg-surface-raised
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  def board_map_data(board_map, game_master:)
    game_master ? game_master_board_data(board_map) : player_board_data(board_map)
  end

  def board_zoom_data(board_map)
    { controller: "board-zoom", action: MOVING_KEYS_ACTIONS,
      board_zoom_columns_value: board_map.columns, board_zoom_rows_value: board_map.rows }
  end

  def board_tokens_data(game_map, game_master:)
    data = { room_board_target: "tokens", tokens: board_tokens_json(game_map, game_master:) }
    game_master ? data.merge(blocked_cells: board_blocked_cells_json(game_map)) : data
  end

  def board_tokens_json(game_map, game_master:)
    tokens = game_map.board_tokens.includes(:character)
    seen_tokens = game_master ? tokens : tokens.reject(&:hidden?)
    seen_tokens.map { |token| board_token_data(token, game_master:) }.to_json
  end

  def board_blocked_cells_json(game_map)
    (game_map.drawn? ? game_map.passage.blocked_cells : []).to_json
  end

  def empty_board_text(game_master:)
    game_master ? t("game_rooms.board.empty_for_game_master") : t("game_rooms.board.empty_for_players")
  end

  def board_map?(game_room, game_map)
    game_room.game_table.board_game_map_id == game_map.id
  end

  def board_map_button_classes
    "#{button_classes(:secondary, size: :compact)} h-7 px-2.5 text-xs select-none " \
      "aria-pressed:border-brass aria-pressed:bg-primary-soft aria-pressed:text-primary-soft-ink"
  end

  private

  def board_token_data(token, game_master:)
    { id: token.id, name: token.character.name, kind: token.character.kind, column: token.column, row: token.row,
      number: token.shown_number, letter: (token.letter if game_master), hidden: token.hidden? }
  end

  def game_master_board_data(board_map)
    shared_board_data(board_map, KEPT_FROM_GAME_MASTER).merge(action: "#{ZOOM_ACTIONS} #{GAME_MASTER_ACTIONS}",
                                                              map_preview_show_natural_blocks_value: true)
  end

  def player_board_data(board_map)
    shared_board_data(board_map, KEPT_FROM_PLAYERS).merge(action: ZOOM_ACTIONS)
  end

  def shared_board_data(board_map, kept_keys)
    game_map_preview_data(board_map).merge(room_board_target: "map", board_zoom_target: "map",
                                           map_preview_layout_value: board_map.layout.except(*kept_keys).to_json,
                                           map_preview_token_characters_value: {}.to_json)
  end
end
