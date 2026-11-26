module BoardHelper
  GAME_MASTER_ACTIONS = "click->room-board#placeAtPointer contextmenu->room-board#dropCreatureWithRightClick".freeze
  KEPT_FROM_PLAYERS = %w[tokens blocked].freeze

  def board_map_data(board_map, game_master:)
    game_master ? game_master_board_data(board_map) : player_board_data(board_map)
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

  def game_master_board_data(board_map)
    game_map_preview_data(board_map).merge(room_board_target: "map", action: GAME_MASTER_ACTIONS,
                                           map_preview_show_natural_blocks_value: true)
  end

  def player_board_data(board_map)
    layout_for_players = board_map.layout.except(*KEPT_FROM_PLAYERS)
    game_map_preview_data(board_map).merge(room_board_target: "map",
                                           map_preview_layout_value: layout_for_players.to_json,
                                           map_preview_token_characters_value: {}.to_json)
  end
end
