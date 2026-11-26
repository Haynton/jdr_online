# A player changes the inventory of their character, from the panel « Inventaire » of the game room: equips an
# armour, a shield or a weapon, or takes it off (update; decision of 26 November: a switch « Équipé », the armour and
# the shield one at a time, Equippable), or takes one of an item out (destroy; decision of 26 November: one at a time,
# an arrow shot or a potion drunk; the last one, asked first, removes the line). Saved: only a player accepted at the
# table, and only an item of their own character; anyone else gets a 404. The answer redraws the panel in place, which
# stays open
module GameTables
  class InventoryItemsController < ApplicationController
    before_action :set_participation_and_item

    def update
      raise ActiveRecord::RecordNotFound unless @inventory_item.equippable?

      @inventory_item.equip(params[:equipped] == "1")
      redraw_inventory
    end

    def destroy
      @inventory_item.take_one_away
      redraw_inventory
    end

    private

    def set_participation_and_item
      @participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @inventory_item = @participation.character&.inventory_items&.find_by(id: params[:id])
      raise ActiveRecord::RecordNotFound unless @inventory_item
    end

    def redraw_inventory
      game_room = GameRoom.new(@participation)
      render turbo_stream: turbo_stream.replace("game-room-inventory", partial: "game_rooms/panels/inventory",
                                                                       locals: { game_room: game_room })
    end
  end
end
