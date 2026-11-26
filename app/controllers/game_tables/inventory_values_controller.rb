# A player takes an amount out of a value kept with the inventory of their character (the gold pieces spent), from the
# panel « Inventaire » of the game room (Anthony's request of 26 November). A number of the template, among those the
# panel shows (PlayerSheetPanelsHelper#own_inventory_play_fields); never more than the character has. Saved: only a
# player accepted at the table, for their own character; anyone else gets a 404. The answer redraws the panel in place,
# with the error under its field when the amount is refused
module GameTables
  class InventoryValuesController < ApplicationController
    def update
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      character = participation.character
      field = removable_field(character)
      error = take_amount_out(character, field, Integer(params[:amount].to_s, exception: false))

      locals = { game_room: GameRoom.new(participation), value_errors: { field["key"] => error } }
      render turbo_stream: turbo_stream.replace("game-room-inventory", partial: "game_rooms/panels/inventory",
                                                                       locals: locals),
             status: error ? :unprocessable_content : :ok
    end

    private

    def removable_field(character)
      field = character && helpers.own_inventory_play_fields(character).find do |candidate|
        candidate["key"] == params[:key]
      end
      raise ActiveRecord::RecordNotFound unless field && helpers.own_removable_value?(character, field)

      field
    end

    # The error to show, nil once the amount is taken out
    def take_amount_out(character, field, amount)
      current = character.sheet[field["key"]].to_i
      return t(".invalid_amount", count: current) unless amount&.between?(1, current)

      character.sheet = character.sheet.merge(field["key"] => current - amount)
      t(".not_saved") unless character.save
    end
  end
end
