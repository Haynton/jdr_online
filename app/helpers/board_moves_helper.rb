# What a token dragged on the board needs in the page (room_board_controller.js, map_editor/board_moves.js): the
# actions of the board, who moves what, the length of a cell, and the words of the distance shown while dragging
module BoardMovesHelper
  MOVE_ACTIONS = %w[
    pointerdown->room-board#pressToken pointermove->room-board#dragToken pointerup->room-board#dropToken
    pointercancel->room-board#cancelTokenDrag
  ].join(" ").freeze

  # Who moves everything, the length of a cell and its unit (the template's, GameTable#grid), and the distance in cells
  # when the template gives none
  def board_move_data(game_room)
    grid = game_room.game_table.grid
    { room_board_game_master_value: game_room.game_master?, room_board_cell_length_value: grid["cell_length"].to_f,
      room_board_distance_label_value: t("game_rooms.board.move_distance", distance: "__DISTANCE__",
                                                                           unit: grid["unit"]),
      room_board_cells_labels_value: board_cells_labels.to_json }
  end

  # A player moves the token of their own complete character and those of its companions
  def board_movable_character_ids(character)
    return [] unless character&.complete?

    [character.id] + character.companions.ids
  end

  private

  def board_cells_labels
    %w[one other].index_with { |form| t("game_rooms.board.move_cells.#{form}", count: "__COUNT__") }
  end
end
