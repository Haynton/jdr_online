# Saves which entries of a kind (the spells, the items) of its template a table offers, from the boxes ticked on its
# step "Spells and items": the others are turned off for the table (game_tables.disabled_catalog_keys, nothing is
# deleted), never an item of the starting equipment (Catalogs::StartingEquipmentItemKeys), whatever is sent
module Catalogs
  class OfferedEntriesUpdater
    def initialize(game_table, kind:)
      @game_table = game_table
      @kind = kind
    end

    def call(offered_keys)
      turned_off = template_keys - offered_keys.to_a.map(&:to_s) - locked_keys
      @game_table.update!(disabled_catalog_keys: @game_table.disabled_catalog_keys.to_h.merge(@kind => turned_off.sort))
    end

    private

    def template_keys
      CatalogEntry.where(sheet_template_id: @game_table.sheet_template_id, kind: @kind).pluck(:key)
    end

    def locked_keys
      @kind == "item" ? StartingEquipmentItemKeys.new(@game_table).call : []
    end
  end
end
