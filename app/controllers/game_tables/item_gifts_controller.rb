# The game master gives an item to a player from the game room (the panel « Objets »): a copy of an item the table
# offers (Catalogs::TableCatalog) goes into the inventory of the character of one of its players, with how many. Checked
# by the server: the game master of the table (TableOfGameMaster), an item of its catalog, a character of one of its
# players; anything else is a 404. A weapon, an armour, a shield or ammunition may get a magic (Catalogs::Enchantments:
# +1, Flame Tongue...), only one that goes on it. The gift is written in the feed of the table (ChatMessage), for
# everyone; back to the room, the panel still open, it is also said in a bubble
module GameTables
  class ItemGiftsController < ApplicationController
    include TableOfGameMaster

    QUANTITIES = (1..99)

    def create
      item = Catalogs::TableCatalog.new(@game_table).entries("item").find_by!(key: params.require(:key))
      character = @game_table.characters.pc.find(params.require(:character_id))
      quantity = params[:quantity].to_i.clamp(QUANTITIES.min, QUANTITIES.max)
      given = InventoryItem.from_entry(item, quantity: quantity, enchantment: enchantment_for(item))
      character.inventory_items << given
      ChatMessage.record_event(@game_table, :item_given, item: given.name, character: character.name, count: quantity)
      redirect_to game_table_path(@game_table),
                  notice: t(".given", count: quantity, item: given.name, character: character.name)
    end

    private

    # The magic put on it (« Magie »), only one that goes on that item; none for a plain item
    def enchantment_for(item)
      key = params[:enchantment].presence
      return unless key

      Catalogs::Enchantments.new(@game_table).for(item).find { |enchantment| enchantment.key == key } ||
        raise(ActiveRecord::RecordNotFound)
    end
  end
end
