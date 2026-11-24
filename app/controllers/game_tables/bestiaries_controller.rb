# The bestiary of a table, in a window over its step "NPCs and enemies": the creatures of the catalog of its template
# the table offers (Catalogs::TableCatalog), by challenge rating, each with "Add" (GameTables::NpcsController#create,
# which copies it). The window stays open to add several. Beside the search, the lists of the fields the template
# filters on (CatalogFiltersHelper: the challenge rating, the type)
module GameTables
  class BestiariesController < ApplicationController
    include TableOfGameMaster
    include VariesOnTurboFrame

    def show
      @creatures = Catalogs::TableCatalog.new(@game_table).entries("monster").to_a
      fields = helpers.catalog_entry_shown_fields(@game_table, "monster")
      @filter_keys = helpers.catalog_filter_keys(fields)
      @filters = helpers.catalog_filters(fields, @creatures)
    end
  end
end
