# Offers or turns off one entry of the catalog of a table (a spell, an item), from its switch on the step "Spells and
# items": a template entry turned off goes into game_tables.disabled_catalog_keys (nothing is deleted). An item of the
# starting equipment turned off leaves the starting equipment of the table (decision of 24 November: the game master
# says which items it holds; CharacterSheets::StartingEquipment skips an item the table does not offer)
module Catalogs
  class OfferedEntriesUpdater
    def initialize(game_table, kind:)
      @game_table = game_table
      @kind = kind
    end

    def call(key, offered:)
      keys = turned_off_keys - [key]
      keys << key unless offered
      @game_table.update!(disabled_catalog_keys: @game_table.disabled_catalog_keys.to_h.merge(@kind => keys.sort))
    end

    private

    def turned_off_keys
      @game_table.disabled_catalog_keys.to_h[@kind].to_a
    end
  end
end
