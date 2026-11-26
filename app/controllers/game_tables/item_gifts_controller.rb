# The game master gives an item to a player from the game room (the panel « Objets »): a copy of an item the table
# offers (Catalogs::TableCatalog) goes into the inventory of the character of one of its players, with how many.
# Checked by the server: the game master of the table (TableOfGameMaster), an item of its catalog, a character of
# one of its players; anything else is a 404. Back to the room, the panel still open, the gift said in a bubble
# (nothing else in the room shows it)
module GameTables
  class ItemGiftsController < ApplicationController
    include TableOfGameMaster

    QUANTITIES = (1..99)

    def create
      item = Catalogs::TableCatalog.new(@game_table).entries("item").find_by!(key: params.require(:key))
      character = @game_table.characters.pc.find(params.require(:character_id))
      quantity = params[:quantity].to_i.clamp(QUANTITIES.min, QUANTITIES.max)
      character.inventory_items << InventoryItem.from_entry(item, quantity: quantity)
      redirect_to game_table_path(@game_table),
                  notice: t(".given", count: quantity, item: item.name, character: character.name)
    end
  end
end
