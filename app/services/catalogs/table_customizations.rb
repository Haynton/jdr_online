# What a table customizes of a kind of its catalog (the spells, the items), the only entries its step "Spells and
# items" lists (decision of 24 November: every entry of the template is offered at first, the step showing them all
# was too heavy): its own entries (copies of entries of its template, entries it added), then the entries of its
# template it turned off without copying them, by name. With the originals of its copies, which tell a copy changed
# from a copy only listed, and the items of the starting equipment (said under their name)
module Catalogs
  class TableCustomizations
    List = Data.define(:kind, :entries, :originals, :starting_keys)

    def initialize(game_table)
      @game_table = game_table
    end

    def list(kind)
      own_entries = @game_table.catalog_entries.where(kind: kind).to_a
      turned_off = template_entries(kind).where(key: turned_off_keys(kind) - own_entries.map(&:key)).to_a
      List.new(kind: kind, entries: sorted(own_entries + turned_off),
               originals: template_entries(kind).where(key: own_entries.map(&:key)).index_by(&:key),
               starting_keys: kind == "item" ? StartingEquipmentItemKeys.new(@game_table).call : [])
    end

    # The keys the table lists already: its own entries and the entries it turned off
    def listed_keys(kind)
      @game_table.catalog_entries.where(kind: kind).pluck(:key) | turned_off_keys(kind)
    end

    private

    def template_entries(kind)
      CatalogEntry.where(sheet_template_id: @game_table.sheet_template_id, kind: kind)
    end

    def turned_off_keys(kind)
      @game_table.disabled_catalog_keys.to_h[kind].to_a
    end

    def sorted(entries)
      entries.sort_by { |entry| I18n.transliterate(entry.name).downcase }
    end
  end
end
