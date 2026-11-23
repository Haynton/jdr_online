# What a game table offers of a kind (spells, items), decision of 23 November: the catalog of its template, less the
# entries the game master turned off for the table (game_tables.disabled_catalog_keys), with the table's own copy in
# place of an entry it changed (same key), plus the entries the game master added. A relation, so that the readers
# chain their own scopes on it (CharacterSheets::SpellChoices, CharacterSheets::StartingEquipment): nothing else reads
# a catalog for a table
module Catalogs
  class TableCatalog
    def initialize(game_table)
      @game_table = game_table
    end

    def entries(kind)
      turned_off = turned_off_keys(kind)
      own_entries = CatalogEntry.where(game_table_id: @game_table.id, kind: kind)
      template_entries = CatalogEntry.where(sheet_template_id: @game_table.sheet_template_id, kind: kind)
                                     .where.not(key: turned_off + own_entries.pluck(:key))
      template_entries.or(own_entries.where.not(key: turned_off))
    end

    private

    # The keys of the entries of its template the table does not use, for this kind ("spell")
    def turned_off_keys(kind)
      @game_table.disabled_catalog_keys.to_h[kind].to_a
    end
  end
end
