# The key of an entry a game master adds to the catalog of a table, made from its name ("Boule de feu maison" gives
# boule-de-feu-maison), never one the template or the table uses already for that kind (a number added then). The key
# is never shown: it names the entry in the copies the characters keep
module Catalogs
  class NewEntryKey
    def initialize(game_table, kind:)
      @game_table = game_table
      @kind = kind
    end

    def call(name)
      base = I18n.transliterate(name.to_s).parameterize.presence || "entry"
      return base unless taken?(base)

      (2..).lazy.map { |number| "#{base}-#{number}" }.find { |key| !taken?(key) }
    end

    private

    def taken?(key)
      CatalogEntry.where(kind: @kind, key: key)
                  .where(sheet_template_id: @game_table.sheet_template_id).or(
                    CatalogEntry.where(kind: @kind, key: key, game_table_id: @game_table.id)
                  ).exists?
    end
  end
end
